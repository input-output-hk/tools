{-# LANGUAGE ScopedTypeVariables #-}

module Example where

import Bag
import GHC.Plugins
import GHC.Iface.Load hiding (loadCore)
import GHC.Iface.Syntax
import GHC.IfaceToCore hiding (tcIfaceModGuts)
import GHC.Tc.Types
import GHC.Tc.Utils.Monad
import GHC.Hs.Binds
import GHC.Hs.Extension
import GHC.Core.ConLike
import Maybes as M
import GHC.Iface.Env
import GHC.Iface.Binary
import GHC.Core.InstEnv
import GHC.Core.FamInstEnv
import GHC.CoreToIface
import GHC.Types.Name.Env
import Control.Monad
import GHC.Hs.Expr


-- We use the `interfaceWriteAction` to access the core bindings that are in the
-- `ModGuts` as a result of the whole core pipeline. We then use serialise those
-- bindings into the interface file using `registerInterfaceDataWith` to produce
-- an extensible interface field from a plugin.

-- We use the `typeCheckResultAction` to intercept the start of the core pipeline
-- and perform our inlining step before any of the other core steps have run,
-- including GHC's normal optimisation passes.
plugin :: Plugin
plugin = defaultPlugin { installCoreToDos      = install
                       , typeCheckResultAction = corePlugin
                       , interfaceWriteAction  = interfacePlugin
                       }


install :: [CommandLineOption] -> [CoreToDo] -> CoreM [CoreToDo]
install args todos | elem "inline" args = return (CoreDoPluginPass "plutus" plutus : CoreDoPluginPass "printer" printer : todos)
                   | otherwise          = return (                                   CoreDoPluginPass "printer" printer : todos)


printer :: ModGuts -> CoreM ModGuts
printer guts = do
  env <- getHscEnv
  liftIO . putStrLn $ showSDoc (hsc_dflags env) (ppr (mg_binds guts))
  return guts


plutus :: ModGuts -> CoreM ModGuts
plutus guts = do
  env    <- getHscEnv
  lookup <- liftIO $ loadDependencies env
  return guts{ mg_binds = map (inlineCore lookup) binds }
  where
    binds = mg_binds guts

inlineCore :: (Name -> Maybe (Bind CoreBndr)) -> Bind Id -> Bind Id
inlineCore lookup (NonRec n expr) = NonRec n (inlineCoreExpr lookup expr)
inlineCore lookup b               = b


inlineCoreExpr :: (Name -> Maybe (Bind CoreBndr)) -> Expr Id -> Expr Id
inlineCoreExpr lookup = go
  where
    go (Var v) = case lookup (varName v) of
      Just (NonRec _ expr) -> expr
      Nothing              -> Var v
    go (Lit l          ) = Lit l
    go (App e1 e2      ) = App (go e1) (go e2)
    go (Lam b e        ) = Lam b (go e)
    go (Let b e        ) = Let b (go e)
    go (Case e b t alts) = Case e b t (map goAlt alts)
    go (Cast e coer    ) = Cast (go e) coer
    go (Tick ti e      ) = Tick ti (go e)
    go (Type t         ) = Type t
    go (Coercion c     ) = Coercion c

    goAlt (con, bndrs, rhs) = (con, bndrs, go rhs)


-- Here we perform the serialisation of the `mg_binds` field from the `ModGuts`.
-- Note, the deserialisation loading functions later require the `SrcSpan`, so
-- we include it in the serialised data.
interfacePlugin :: [CommandLineOption] -> HscEnv -> ModDetails -> ModGuts -> PartialModIface -> IO PartialModIface
interfacePlugin _ env _ guts iface = do
  registerInterfaceDataWith "plutus/core-bindings" env $ \bh ->
    putWithUserData (const $ return ()) bh (mg_loc guts, map toIfaceBind' $ mg_binds guts)
  return iface


isRealBinding :: Bind Id -> Bool
isRealBinding (NonRec n _) = isExternalName (idName n)
isRealBinding _ = True


toIfaceBind' :: Bind Id -> (Bool, IfaceBinding)
toIfaceBind' b = (isRealBinding b, toIfaceBind b)


-- Perform interface `typecheck` loading from this binding's extensible interface
-- field within the deserialised `ModIface` to load the bindings that the field
-- contains, if the field exists.
loadCoreBindings :: ModIface -> IfL (Maybe [Bind CoreBndr])
loadCoreBindings iface@ModIface{mi_module = mod} = do
  liftIO $ putStrLn "loadCoreBindings"
  ncu <- mkNameCacheUpdater
  mbinds <- liftIO (readIfaceFieldWith "plutus/core-bindings" (getWithUserData ncu) iface)
  case mbinds of
    Just (loc, ibinds) -> Just . catMaybes <$> mapM (tcIfaceBinding mod loc) ibinds
    Nothing            -> liftIO (print "no-loadCoreBindings") >> return Nothing


-- Attempt to load the binding for a given name directly from an interface file.
lookupCore :: Name
           -> IfL (Maybe (Bind CoreBndr))
lookupCore n = do
  iface <- loadPluginInterface (text "lookupCore") (nameModule n)
  binds <- loadCoreBindings iface
  return $ lookupName n =<< binds


lookupName :: Name -> [Bind CoreBndr] -> Maybe (Bind CoreBndr)
lookupName n bs = lookupNameEnv (mkNameEnvWith nameOf bs) n
  where
    nameOf (NonRec n _)     = idName n
    nameOf (Rec ((n, _):_)) = idName n


-- Load the dependencies from the environment, and return a function to lookup bindings:
-- This function is intended to load all-at-once and cache the result, whereas `lookupCore`
-- works as more of a one-off call.
loadDependencies :: HscEnv
                 -> IO (Name -> Maybe (Bind CoreBndr))
loadDependencies env = initIfaceLoad env $ do
  liftIO $ print ("mods", length mods)
  binds <- forM mods $ \m -> do
    iface <- loadPluginInterface (text "lookupCore") m
    initIfaceLcl m (text "core") False $ loadCoreBindings iface
  liftIO $ print ("loadDependencies", length $ join $ catMaybes binds)
  return $ \n -> lookupName n (join $ catMaybes binds)
  where
    mods = map ms_mod . mgModSummaries $ hsc_mod_graph env


corePlugin :: [CommandLineOption] -> ModSummary -> TcGblEnv -> TcM TcGblEnv
corePlugin _ _ gbl = return gbl
-- corePlugin _ _mod_summary gbl = initIfaceTcRn $ do
--   hsc_env <- getTopEnv

--   liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr (mgModSummaries $ hsc_mod_graph hsc_env))

--   let mod_summary = (mgModSummaries $ hsc_mod_graph hsc_env) !! 1

--   do
--     let iface_path = msHiFilePath mod_summary
--     read_result <- readIface (ms_mod mod_summary) iface_path
--     case read_result of
--         M.Failed err -> liftIO $ putStrLn "No iface"
--         M.Succeeded iface -> do
--           liftIO $ do
--              core <- initIfaceLoad hsc_env $ do
--                gbl <- getGblEnv
--                case if_rec_types gbl of
--                  Just (mod, get_type_env) -> do
--                    liftIO $ putStrLn "get_type_env"
--                    env <- get_type_env
--                    liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr mod)
--                    liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr env)
--                  Nothing -> liftIO $ putStrLn "No get_type_env"
--                liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr mod_summary)
--                liftIO $ putStrLn "Interface"
--                initIfaceLcl (ms_mod mod_summary) (text "CORE") False $ do
--                  liftIO $ putStrLn "init"
--                  lcl <- getLclEnv
--                  liftIO $ putStrLn "lcl"
--                  liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr (if_id_env lcl))
--                  liftIO $ putStrLn "id_env"
--                  loadCoreBindings iface
--              putStrLn $ "Loaded core:"
--              case core of
--                Just binds -> print $ showSDoc (hsc_dflags hsc_env) (ppr binds)
--                Nothing -> putStrLn "No core field"

--   binds' <- inlineCore (tcg_binds gbl)
--   return $ gbl { tcg_binds = binds' }


-- A `Bag` is an unordered collection with duplicates, and the module is included in GHC
-- inlineCore :: Bag (Located (HsBind GhcTc)) -> IfG (Bag (Located (HsBind GhcTc)))
-- inlineCore = mapM inlineLocBind


-- We don't need source location information for inlining
inlineLocBind :: Located (HsBind GhcTc) -> IfG (Located (HsBind GhcTc))
inlineLocBind = mapM inlineBind


-- The real binding, indexed by the `GhcPass 'TypeChecked` type
inlineBind :: HsBind GhcTc -> IfG (HsBind GhcTc)
inlineBind x@AbsBinds{}   = return x
inlineBind x@PatBind{}    = return x
inlineBind x@PatSynBind{} = return x
inlineBind (VarBind ext vid rhs) = VarBind ext vid <$> inlineLocExpr rhs
inlineBind (FunBind ext fid matches tick) = do
  matches' <- inlineMatches matches
  return $ FunBind ext fid matches' tick


inlineLocExpr :: Located (HsExpr GhcTc) -> IfG (Located (HsExpr GhcTc))
inlineLocExpr = mapM inlineExpr


-- The real RHS expressions
inlineExpr :: HsExpr GhcTc -> IfG (HsExpr GhcTc)
inlineExpr (HsVar _ locId) = undefined
inlineExpr x = return x


inlineMatches :: MatchGroup GhcTc (Located (HsExpr GhcTc)) -> IfG (MatchGroup GhcTc (Located (HsExpr GhcTc)))
inlineMatches (MG ext alts origin) = do
  alts' <- mapM (mapM (mapM inlineMatch)) alts
  return (MG ext alts' origin)


inlineMatch :: Match GhcTc (Located (HsExpr GhcTc)) -> IfG (Match GhcTc (Located (HsExpr GhcTc)))
inlineMatch (Match ext ctxt pats grhss) = Match ext ctxt pats <$> inlineGuardedRHSs grhss


inlineGuardedRHSs :: GRHSs GhcTc (Located (HsExpr GhcTc)) -> IfG (GRHSs GhcTc (Located (HsExpr GhcTc)))
inlineGuardedRHSs (GRHSs ext grhss lclBinds) = GRHSs ext <$> mapM (mapM inlineGuardedRHS) grhss <*> mapM inlineWhereClause lclBinds


inlineGuardedRHS :: GRHS GhcTc (Located (HsExpr GhcTc)) -> IfG (GRHS GhcTc (Located (HsExpr GhcTc)))
inlineGuardedRHS (GRHS x guards body) = GRHS x guards <$> mapM inlineExpr body


inlineWhereClause :: HsLocalBinds GhcTc -> IfG (HsLocalBinds GhcTc)
inlineWhereClause x@HsIPBinds{}       = return x
inlineWhereClause x@EmptyLocalBinds{} = return x
inlineWhereClause (HsValBinds x (ValBinds xvbs binds sigs)) = do
  binds' <- mapM (mapM inlineBind) binds
  return $ HsValBinds x (ValBinds xvbs binds' sigs)


-------------------------------------------------------------------------------
-- Interface loading for top-level bindings
-------------------------------------------------------------------------------

loadCore :: ModIface -> IfL (Maybe ModGuts)
loadCore iface = do
  ncu <- mkNameCacheUpdater
  mapM tcIfaceModGuts =<< liftIO (readIfaceFieldWith "ghc/core" (getWithUserData ncu) iface)

tcIfaceBinding :: Module -> SrcSpan -> (Bool, IfaceBinding) -> IfL (Maybe (Bind Id))
tcIfaceBinding mod loc ibind = do
  bind <- tryAllM $ tcIfaceBinding' mod loc ibind
  case bind of
    Left _ -> return Nothing
    Right b -> do
        let (NonRec n _) = b
        liftIO $ putStrLn (nameStableString $ idName n)
        return $ Just b

tcIfaceBinding' :: Module -> SrcSpan -> (Bool, IfaceBinding) -> IfL (Bind Id)
tcIfaceBinding' _   _    (_p, (IfaceRec _)) = panic "tcIfaceBinding: expected NonRec at top level"
tcIfaceBinding' mod loc b@(p, IfaceNonRec (IfLetBndr fs ty info ji) rhs) = do
  name <- lookupIfaceTop (mkVarOccFS fs)


  -- name    <- newGlobalBinder mod (mkVarOccFS fs) loc

  ty'     <- tcIfaceType ty
  -- id_info <- tcIdInfo False TopLevel name ty' info
  let id = mkExportedVanillaId name ty'
             `asJoinId_maybe` tcJoinInfo ji


  liftIO $ putStrLn "-----------------------------"
  liftIO $ print (nameStableString name, isInternalName name, isExternalName name, isSystemName name, isWiredInName name)
  liftIO $ putStrLn "------------"
  dflags <- getDynFlags
  -- Env env _ _ _ <- getEnv
  -- liftIO $ do
  --   nc <- readIORef $ hsc_NC env
  --   putStrLn $ showSDoc dflags (ppr $ nsNames nc)
  --   return ()


  liftIO $ putStrLn $ showSDoc dflags (ppr rhs)
  rhs' <- tcIfaceExpr rhs
  liftIO $ putStrLn "------------"
  liftIO $ putStrLn $ showSDoc dflags (ppr rhs')
  -- liftIO $ putStrLn "------------"
  -- liftIO $ print (b == toIfaceBinding (NonRec id rhs'))
  liftIO $ putStrLn "-----------------------------"
  return (NonRec id rhs')

-- tcIfaceBinding' (IfaceRec pairs)
--   = do { ids <- mapM tc_rec_bndr (map fst pairs)
--        ; extendIfaceIdEnv ids $ do
--        { pairs' <- zipWithM tc_pair pairs ids
--        ; return (Rec pairs') } }
--  where
--    tc_rec_bndr (IfLetBndr fs ty _ ji)
--      = do { name <- newIfaceName (mkVarOccFS fs)
--           ; ty'  <- tcIfaceType ty
--           ; return (mkLocalId name ty' `asJoinId_maybe` tcJoinInfo ji) }
--    tc_pair (IfLetBndr _ _ info _, rhs) id
--      = do { rhs' <- tcIfaceExpr rhs
--           ; id_info <- tcIdInfo False {- Don't ignore prags; we are inside one! -}
--                                 NotTopLevel (idName id) (idType id) info
--           ; return (setIdInfo id id_info, rhs') }

tcIfaceModGuts :: IfaceModGuts -> IfL ModGuts
tcIfaceModGuts (IfaceModGuts f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18
                        f19 f20 f21 f22 f23 f24 f25 f26 f27 f28 f29) = do
  f10' <- mapM tcIfaceTyCon f10
  f11' <- mapM tcIfaceInst f11
  f12' <- mapM tcIfaceFamInst f12
  f13' <- mapM tcIfacePatSyn f13
  f14' <- mapM tcIfaceRule f14
  f15' <- catMaybes <$> mapM (tcIfaceBinding f1 f3) f15
  f23' <- extendInstEnvList emptyInstEnv <$> mapM tcIfaceInst f23
  f24' <- extendFamInstEnvList emptyFamInstEnv <$> mapM tcIfaceFamInst f24

  return $ ModGuts f1 f2 f3 f4 f5 f6 f7 f8 f9 f10' f11' f12' f13' f14' f15' f16 f17 f18
                        f19 f20 f21 f22 f23' f24' f25 f26 f27 f28 f29

  where
    tcIfacePatSyn ps = do
      decl <- tcIfaceDecl False ps
      case decl of
        AConLike (PatSynCon ps') -> return ps'
        _                        -> panic "tcIfaceModGuts: a non-patsyn decl was stored in the patsyns field"
