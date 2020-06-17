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


plugin :: Plugin
plugin = defaultPlugin { typeCheckResultAction = corePlugin
                       , interfaceWriteAction  = interfacePlugin
                       }


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


loadCoreBindings :: ModIface -> IfL (Maybe [Bind CoreBndr])
loadCoreBindings iface@ModIface{mi_module = mod} = do
  liftIO $ putStrLn "loadCoreBindings"
  ncu <- mkNameCacheUpdater
  mbinds <- liftIO (readIfaceFieldWith "plutus/core-bindings" (getWithUserData ncu) iface)
  case mbinds of
    Just (loc, ibinds) -> Just . catMaybes <$> mapM (tcIfaceBinding mod loc) ibinds
    Nothing            -> liftIO (print "no-loadCoreBindings") >> return Nothing


lookupCore :: ModSummary
           -> Name
           -> IfL (Maybe (Bind CoreBndr))
lookupCore summary n = do
  iface <- loadPluginInterface (text "lookupCore") (ms_mod summary)
  binds <- loadCoreBindings iface
  return $ lookupName n =<< binds


lookupName :: Name -> [Bind CoreBndr] -> Maybe (Bind CoreBndr)
lookupName = undefined


-- Load the dependencies from the environment, and return a function to lookup bindings:
loadDependencies :: HscEnv
                 -> ModSummary
                 -> Name
                 -> IfL (Maybe (Bind CoreBndr))
loadDependencies = undefined


corePlugin :: [CommandLineOption] -> ModSummary -> TcGblEnv -> TcM TcGblEnv
corePlugin _ _mod_summary gbl = initIfaceTcRn $ do
  hsc_env <- getTopEnv

  liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr (mgModSummaries $ hsc_mod_graph hsc_env))

  let mod_summary = (mgModSummaries $ hsc_mod_graph hsc_env) !! 1

  do
    let iface_path = msHiFilePath mod_summary
    read_result <- readIface (ms_mod mod_summary) iface_path
    case read_result of
        M.Failed err -> liftIO $ putStrLn "No iface"
        M.Succeeded iface -> do
          liftIO $ do
             core <- initIfaceLoad hsc_env $ do
               gbl <- getGblEnv
               case if_rec_types gbl of
                 Just (mod, get_type_env) -> do
                   liftIO $ putStrLn "get_type_env"
                   env <- get_type_env
                   liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr mod)
                   liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr env)
                 Nothing -> liftIO $ putStrLn "No get_type_env"
               liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr mod_summary)
               liftIO $ putStrLn "Interface"
               initIfaceLcl (ms_mod mod_summary) (text "CORE") False $ do
                 liftIO $ putStrLn "init"
                 lcl <- getLclEnv
                 liftIO $ putStrLn "lcl"
                 liftIO $ putStrLn $ showSDoc (hsc_dflags hsc_env) (ppr (if_id_env lcl))
                 liftIO $ putStrLn "id_env"
                 loadCoreBindings iface
             putStrLn $ "Loaded core:"
             case core of
               Just binds -> print $ showSDoc (hsc_dflags hsc_env) (ppr binds)
               Nothing -> putStrLn "No core field"

  binds' <- inlineCore (tcg_binds gbl)
  return $ gbl { tcg_binds = binds' }


-- A `Bag` is an unordered collection with duplicates, and the module is included in GHC
inlineCore :: Bag (Located (HsBind GhcTc)) -> IfG (Bag (Located (HsBind GhcTc)))
inlineCore = mapM inlineLocBind


-- We don't need source location information for inlining
inlineLocBind :: Located (HsBind GhcTc) -> IfG (Located (HsBind GhcTc))
inlineLocBind = mapM inlineBind


-- The real binding, indexed by the `GhcPass 'TypeChecked` type
inlineBind :: HsBind GhcTc -> IfG (HsBind GhcTc)
inlineBind x@FunBind{}    = return x
inlineBind x@PatBind{}    = return x
inlineBind x@VarBind{}    = return x
inlineBind x@AbsBinds{}   = return x
inlineBind x@PatSynBind{} = return x



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
