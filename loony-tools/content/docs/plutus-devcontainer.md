# Plutus Development Container

The tools team works on a full IDE integration for Plutus.  This work is split
between the plutus and the tools team.  The current focus is on getting ghcide
to work nicely with plugins (as the plutus compiler is conceptually a plugin),
and have this all contained in a docker container, which can drive a Vistual
Studio Code instance. Or any other remote capable editor with a Language Server
client implementation.

Eventually we want to provide a user friendly option for haskell.nix in the
devcontainer as well, as it will be imperative for plutus contracts to be
reproducable, and haskell.nix would provide us with the necessary infrastructure.
