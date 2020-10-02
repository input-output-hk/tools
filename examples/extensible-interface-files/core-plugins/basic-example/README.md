## Motivation

Plutus acts as an embedded-language compiler hosted within GHC Haskell to compile a Haskell program
into a Plutus AST, which will then be used in code generation for programs to be run on the blockchain.

In order to recover a Plutus AST from a Haskell function, the Plutus plugin inspects the Core of
bindings to essentially inline the AST and provide that to the Plutus compiler. But, plugins are
only fed the bindings of the current module, so we must recover the AST represented by any external
names in a different way.

Currently, without extensible interface files, Plutus uses the unfoldings to recover the Core
represented by a name from an external module. Unfoldings are normally used by GHC perform regular
Haskell inlining. However, this has a number of disadvantages:
* The user needs to annotate all such external bindings with `INLINE`
* Alternately, the `-f-expose-all-unfoldings` flag can be used to equivalently generate unfoldings
  for all bindings in a project or file
* Annotating bindings with `INLINABLE` almost guarantees that a binding is inlined, so doing so
  will very likely cause efficiency problems in code generation. Similarly, the presence of the
  unfoldings produced by the flag also mess with GHC's inlining algorithm.

Instead, we want to demonstrate a more semantically correct version of this using core bindings
exposed in extensible interface files. Extensible interface files allow us to store arbirary
serialisable data within the regular interface files, including data from a non-GHC source.
Additionally, extensible interface files aim to give `.hi` files a more well-defined structure,
so that external tools can interact with them. With this extensibility, we add a flag to GHC to
serialise the `ModGuts` into an interface file field. The `ModGuts` represents the entire compilation
state of a module after the Core pipeline has been run, before it's later converted to STG.
Among other things, the `ModGuts` contains the core bindings for all exported definitions in a
module.

This example project intends to show the process of writing the core interface field, loading it
within the `IfG a`/`IfL a` interface global/local loading environments, and finally using that data
to lookup the right-hand sides of external names that appear in the core that is given in the plugin
environment of the currently compiling module.

## Deliverables

* Example structure of a plugin using extensible interface files and the `-fwrite-core-field` flag
* Usage of loading the `IfG`/`IfL` (interface load) monad environments into `IO`, which can then be
  lifted into the plugin action via `MonadIO`
* Inlining the plugin binds based on the core recovered from interface files of dependencies

## Design and Implementation

We define a `Lib` module, which contains stand-in definitions representing external bindings that
would require being looked up if their names appeared in the right-hand sides of the definitions
in another module. This module is compiled with the `-fwrite-core-field` flag, so its interface
file will contain a field that can be deserialised into a `ModGuts`.

Then, the `Lib` module is imported into the `Main` module, which then makes use of these imported
definitions in its own definitions. `Main` is then compiled with the `Example` plugin, which
performs a version of inlining to immitate Plutus. Because `Lib`'s definitions are external to
`Main`, when the plugin encounters a name from `Lib`, it will have to recover the core from `Lib.hs`'s
core extensible interface field.

The `Example` module, containing the post-type checking plugin, makes use of the core found in
interface files to perform a form of inlining to demonstrate usage for Plutus. The current module's
bindings are found in the plugin argument, `TcGblEnv`, and the `TcM` monad in which the plugin
operates gives us access to other environment data that we require to load interfaces.

## Details

* Loading interface files is done in the `type IfL a = IOEnv (Env IfGbl IfLcl) a` monad, while
  core plugins are in the `CoreM` enviroment. `IfL` is meant to be eventually run in `IO`, and
  `CoreM` is `MonadIO`, so it can be lifted into the plugin, but initialising the interface loading
  does require some extra data:
  * We must first initialise the global enviroment, which requires the `HscEnv`, which can be
    retrieved from `getHscEnv`. This `HscEnv` differs based on the current module being compiled
  * For each external module that is being imported, the local enviroment must be initialised with
    its `Module` data structure, essentially setting that one as active. These `Module`s are able
    to be recovered from the module graph contained in the `HscEnv`

## Building

### GHC

With https://gitlab.haskell.org/ghc/ghc/-/tree/wip/pluginExtFields run:

```
./boot
./configure
make -j8
sudo make install
```

Then include export `/usr/local/bin` into the current session's path.

Additionally, `configure` can be passed a `--prefix=/my/ghc/install/path` flag as an alternative
to `/usr/local/bin`.

### This Package

Makefile targets:
* diff (default): build both with and without the plugin, and compare the resulting core
* vanilla: build without the plugin, and output the core to vanilla.core
* core-inline: build with the plugin, and output the core to inlined.core
* clean: clean build results
* ghcid: run ghcid to provide instant-feedback type-checking
