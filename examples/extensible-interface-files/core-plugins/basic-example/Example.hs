{-# LANGUAGE ScopedTypeVariables, TupleSections #-}

module Example where

import GHC.Data.Bag
import GHC.Plugins
import GHC.Iface.Load hiding (loadCore)
import GHC.Iface.Syntax
import GHC.IfaceToCore hiding (tcIfaceModGuts)
import GHC.Tc.Types
import GHC.Tc.Utils.Monad
import GHC.Hs.Binds
import GHC.Hs.Extension
import GHC.Core.ConLike
import GHC.Iface.Env
import GHC.Iface.Binary
import GHC.Core.InstEnv
import GHC.Core.FamInstEnv
import GHC.CoreToIface
import GHC.Types.Name.Env
import Control.Monad
import GHC.Hs.Expr
import GHC (getModuleGraph)
import Data.IORef
import GHC.Types.Unique.DFM
import System.IO.Unsafe
import Data.Maybe


{-
We add our plugins to the core compiler pipeline. This plugin stage passes us
the existing passes, including those added by GHC and other (previous) plugins,
and expects back a list of passes that we want to include. In this case, we
don't want to remove any existing passes, so we append our passes to the start
and end of the core pipeline.
-}
plugin :: Plugin
plugin = defaultPlugin { installCoreToDos = install }


{-
Our modified core pipeline is as follows:
* `plutus`     - using the `inline` plugin flag:
                 an inlining plugin that mimicks binding AST traversal as a stand-in
                 for Plutus
* `todos`      - the existing core pipeline given by GHC
* `bindsPass`  - print the bindings (after the inliner has optionally run), for `diff`ing
* `printer`    - using the `print` plugin flag:
                 pretty-print the `HscEnv` `ModGuts` to the console, for debugging
* `serialiser` - using the `inline` plugin flag:
                 output core ASTs for bindings into the interface file
-}
install :: [CommandLineOption] -> [CoreToDo] -> CoreM [CoreToDo]
install args todos = return $ join [plutusPass, todos, bindsPass, printerPass, serialiserPass]
  where
    plutusPass     | elem "inline"     args = [CoreDoPluginPass "plutus" plutus]
                   | otherwise              = []
    printerPass    | elem "print"      args = [CoreDoPluginPass "printer" printer]
                   | otherwise              = []
    bindsPass                               = [CoreDoPluginPass "binds" bindsPlug]
    serialiserPass | elem "serialiser" args = [CoreDoPluginPass "serialiser" serialiser]
                   | otherwise              = []


{-
A core plugin pass to print the `mg_binds` to the console.
We return the argument unchanged.
-}
bindsPlug :: ModGuts -> CoreM ModGuts
bindsPlug guts = do
  env <- getHscEnv
  liftIO . putStrLn . showSDoc (hsc_dflags env) . ppr $ mg_binds guts
  return guts


{-
A core plugin pass to print the `HscEnv` and `ModGuts` to the console.
We return the argument unchanged.
-}
printer :: ModGuts -> CoreM ModGuts
printer guts = do
  env <- getHscEnv
  liftIO $ do
    printHscEnv env
    printModGuts env guts
  return guts


{-
From the `HscEnv`, we're interested in:
* The `ModuleGraph`:
  * In one-shot mode, this is empty, because all modues are treated as external
  * In normal mode, this contains the current module, and all of its dependencies
    from the home package
  * We can extract a list of the `ModSummary`s of these modules using `mgModSummaries`
* The `HomePackageTable`:
  * This is a Map (as a `UDFM`) keyed on module name `Unique`s to lookup a structure
    containing the `ModIface` and `ModDetails` of a module
  * This contains the previously compiled modules, but not the current module.
    Because dependencies are always compiled first, we can (in normal mode) assume
    that the dependencies will exist here
  * Again, this is empty in one-shot mode
* The `ExternalPackageState`:
  * This is stored in an IORef, and is modified by opening `ModIface`s of external
    modules
  * Since one-shot mode treats all modules as external, we will find the home package
    modules
  * The `PackageIfaceTable` is a Map (as a `ModuleEnv`) keyed on `Module`s to lookup
    `ModIface`s
-}
printHscEnv :: HscEnv -> IO ()
printHscEnv (HscEnv dflags targets mod_graph _ic hpt eps' nc' _fc' _type_env' _iserv' _dynlinker _ext) = do
  eps <- readIORef eps'
  nc  <- readIORef nc'
  putStrLn . showSDoc dflags $ vcat
    [ text "***HscEnv***"
    , ppr targets
    , ppr (mgModSummaries mod_graph)
    , ppr (mapUDFM (mi_module . hm_iface) hpt)
    , ppr (eltsUFM $ eps_is_boot eps)
    , ppr (moduleEnvKeys $ eps_PIT eps)
    , text "!!!HscEnv!!!"
    ]

{-
From the `ModGuts`, we can retrieve the actual core of the exported bindings for this
module, under the `mg_binds` record field, as a `type CoreProgram = [Bind CoreBndr]`.
-}
printModGuts :: HscEnv -> ModGuts -> IO ()
printModGuts env (ModGuts mod _hsc_src _loc _exports deps _usages _used_th rdr_env _fix_env _tcs _insts _fam_insts _patsyns _rules binds _foreign _foreign_files
                              _warns _anns _complete_sigs _hpc_info _modBreaks _inst_env _fam_inst_env _safe_haskell _trust_pkg _doc_hdr _decl_dogs _arg_docs
                 ) = do
  putStrLn . showSDoc (hsc_dflags env) $ vcat
    [ text "***ModGuts***"
    , ppr mod
    , ppr (dep_mods deps)
    , ppr (dep_pkgs deps)
    , ppr (dep_orphs deps)
    , ppr (dep_finsts deps)
    , ppr (dep_plgins deps)
    , ppr rdr_env
    , ppr binds
    , text "!!!ModGuts!!!"
    ]


{-
Here we use the `registerInterfaceDataWith` machinery of extensible interface files
to record our serialised data as a field in the `HscEnv`, which later gets added to
the `ModGuts` to be written with the `.hi` interface file.

Because the core bindings contain GHC `Name`s and `FastString`s, which are serialised
in a lookup table, we need to use `putWithUserData` to write to a raw `BinHandle`. If
our data didn't contain either of these types, we could use `registerInterfaceData`
to avoid the raw handle and instead go via the `GHC.Binary` instance.

Note that the loading function will later require the `SrcSpan` for error reporting,
so we serialise the `mg_loc` here too.
-}
serialiser :: ModGuts -> CoreM ModGuts
serialiser guts = do
  env <- getHscEnv
  liftIO . registerInterfaceDataWith "plutus/core-bindings" env $ \bh ->
    putWithUserData (const $ return ()) bh (mg_loc guts, map toIfaceBind $ mg_binds guts)
  return guts


{-
For our Plutus stand-in, we first retrieve the `HscEnv`, which is required to lookup
`Name`s within the `HomePackageTable` and `PackageIfaceTable` to perform the knot-tying
of serialised `Iface`* structures into proper in-memory reference-based structures.

We want to cache the binds we load, so we use `newLoadBind` to initialise the `IORef`
for this - giving us an `IO` function mapping `Name`s to `Bind Id`s.
-}
plutus :: ModGuts -> CoreM ModGuts
plutus guts = do
  env    <- getHscEnv
  lookup <- liftIO $ newLoadBind env
  binds' <- liftIO $ mapM (inlineCore lookup) (mg_binds guts)
  return guts{ mg_binds = binds' }


{-
Bindings in GHC have two cases:
* a single regular binding, `NonRec`:
  * top-level bindings that reference each-other are included in this case
* mutually recursive bindings, `Rec`, including:
  * bindings with multiple equations
  * self-referential bindings, such as `xs = ():xs`.
-}
inlineCore :: (Name -> IO (Maybe (Bind CoreBndr))) -> Bind Id -> IO (Bind Id)
inlineCore lookup (NonRec n expr) = NonRec n <$> inlineCoreExpr lookup expr
inlineCore lookup (Rec pairs)     = Rec <$> mapM inlineCorePair pairs
  where
    inlineCorePair (n, b) = (n,) <$> inlineCoreExpr lookup b


{-
We recurse the structure of the `Bind Id` AST to replace one level of `Name`s
with the core data we retrieve using the `lookup` function, if we find the
core in the extensible interface field.

The main case here is the `Var v` constructor, which contains a `Name` that
we want to potentially inline.
-}
inlineCoreExpr :: (Name -> IO (Maybe (Bind CoreBndr))) -> Expr Id -> IO (Expr Id)
inlineCoreExpr lookup = go
  where
    go :: Expr Id -> IO (Expr Id)
    go (Var v) = do
      look <- lookup (varName v)
      return $ case look of
        Just (NonRec _ expr) -> expr
        Nothing              -> Var v
    go (Lit l          ) = return $ Lit l
    go (App e1 e2      ) = App <$> go e1 <*> go e2
    go (Lam b e        ) = Lam b <$> go e
    go (Let b e        ) = Let b <$> go e
    go (Case e b t alts) = Case e b t <$> mapM goAlt alts
    go (Cast e coer    ) = (`Cast` coer) <$> go e
    go (Tick ti e      ) = Tick ti <$> go e
    go (Type t         ) = return $ Type t
    go (Coercion c     ) = return $ Coercion c

    goAlt (con, bndrs, rhs) = (con, bndrs,) <$> go rhs


{-
Retrieve the name of a top-level binding. In the case of recursive bindings,
we assume (based on which types of bindings we have determined become top-level
recursive bindings):
* The binding has at least one case
* All cases have the same `Name`.
-}
nameOf :: Bind Id -> Name
nameOf (NonRec n _)     = idName n
nameOf (Rec ((n, _):_)) = idName n


{-
Perform interface `typecheck` loading from this binding's extensible interface
field within the deserialised `ModIface` to load the bindings that the field
contains, if the field exists.
-}
loadCoreBindings :: ModIface -> IfL (Maybe [Bind CoreBndr])
loadCoreBindings iface@ModIface{mi_module = mod} = do
  ncu <- mkNameCacheUpdater
  mbinds <- liftIO (readIfaceFieldWith "plutus/core-bindings" (getWithUserData ncu) iface)
  case mbinds of
    Just (loc, ibinds) -> Just . catMaybes <$> mapM (tcIfaceBinding mod loc) ibinds
    Nothing            -> return Nothing


{-
Initialise a stateful `IO` function for loading core bindings by loading the
relevant `ModIface` from disk. Each interface that is loaded has its bindings
cached within an `IORef (ModuleEnv (Maybe (NameEnv (Bind CoreBndr))))`.
-}
newLoadBind :: HscEnv -> IO (Name -> IO (Maybe (Bind CoreBndr)))
newLoadBind hscEnv = do
  modBindsR <- newIORef emptyModuleEnv
  return (loadBind modBindsR hscEnv)


loadBind :: IORef (ModuleEnv (Maybe (NameEnv (Bind CoreBndr))))
         -> HscEnv
         -> Name
         -> IO (Maybe (Bind CoreBndr))
loadBind modBindsR env name = do
  eps      <- hscEPS env
  modBinds <- readIORef modBindsR
  case nameModule_maybe name of
   Just mod | Just iface <- lookupIfaceByModule (hsc_HPT env) (eps_PIT eps) mod ->
      case lookupModuleEnv modBinds mod of
        Just Nothing -> return Nothing -- We've already checked this module, and it doesn't have bindings
                                       -- serialised - probably because it's from an external package,
                                       -- but it could also have not been compiled with the plugin.
        Just (Just binds) -> return $ lookupNameEnv binds name -- We've imported this module - lookup the binding.
        Nothing -> do -- Try and import the module.
             bnds <- initIfaceLoad env $
                     initIfaceLcl (mi_semantic_module iface) (text "core") NotBoot $
                       loadCoreBindings iface
             case bnds of
               Just bds -> do
                 let binds' = mkNameEnvWith nameOf bds
                 writeIORef modBindsR (extendModuleEnv modBinds mod (Just binds'))
                 return $ lookupNameEnv binds' name
               Nothing -> return Nothing
   _ -> return Nothing

-------------------------------------------------------------------------------
-- Interface loading for top-level bindings
-------------------------------------------------------------------------------

tcIfaceBinding :: Module -> SrcSpan -> IfaceBinding -> IfL (Maybe (Bind Id))
tcIfaceBinding mod loc ibind = do
  bind <- tryAllM $ tcIfaceBinding' mod loc ibind
  case bind of
    Left _ -> return Nothing
    Right b -> do
        let (NonRec n _) = b
        liftIO $ putStrLn (nameStableString $ idName n)
        return $ Just b

tcIfaceBinding' :: Module -> SrcSpan -> IfaceBinding -> IfL (Bind Id)
tcIfaceBinding' _   _    (IfaceRec _) = panic "tcIfaceBinding: expected NonRec at top level"
tcIfaceBinding' mod loc b@(IfaceNonRec (IfLetBndr fs ty info ji) rhs) = do
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
