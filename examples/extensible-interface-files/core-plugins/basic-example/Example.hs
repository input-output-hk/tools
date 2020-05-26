module Example where

import GHC.Plugins
import GHC.Iface.Load
import GHC.Tc.Types
import GHC.Tc.Utils.Monad

import Control.Monad


plugin :: Plugin
plugin = defaultPlugin { installCoreToDos = corePlugin }


corePlugin :: CorePlugin
corePlugin _ = liftIfL . mapM inlineCore


liftIfL :: IfL a -> CoreM a
liftIfL m = do
  env <- getHscEnv
  mod <- getModule -- I think this is meant to be the module that is the source of the inlinings, not the current module
  liftIO $
    initIfaceLoad env $ -- This may have to load all dependencies, rather than the current module
    initIfaceLcl mod (text "ExamplePlugin") False m


inlineCore :: CoreToDo -> IfL CoreToDo
inlineCore = return
