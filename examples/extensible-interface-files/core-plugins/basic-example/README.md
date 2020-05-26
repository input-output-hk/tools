## Motivation

In order to recover a Plutus AST from a Haskell function, the Plutus plugin inspects the Core of
bindings to essentially inline the AST and provide that to the Plutus compiler. But, plugins are
only fed the bindings of the current module, so we must recover the AST represented by any external
names in a different way.

This example project intends to show this process with extensible interface files.

## Deliverables

* Example structure of a plugin using extensible interface files and the `-fwrite-core-field` flag
* Usage of loading `IfL` (interface load) monad environment into `CoreM` (core plugin) monad environment
* Inlining the plugin binds based on the core recovered from interface files of dependencies

## Design and Implementation

* Loading interface files is done in the `type IfL a = IOEnv (Env IfGbl IfLcl) a` monad, while
  core plugins are in the `CoreM` enviroment. `IfL` is meant to be eventually run in `IO`, and
  `CoreM` is `MonadIO`, so it can be lifted into the plugin, but initialising the interface loading
  does require some extra data:
  * The `HscEnv`, which can be retrieved from `getHscEnv`
  * The `Module`s for each module that's a dependency of the one we're currently compiling, and
    these potentially must be recovered 'manually' from their interface files
