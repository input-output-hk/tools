# Haskell.nix

[haskell.nix](https://github.com/input-output-hk/haskell.nix) is a haskell build
infrastructure for nix.  Nix provides reproducable builds, and haskell.nix provides
the cabal/stack glue code to make nix aware of haskell projects.  We use this to
great success, and the tools team keeps improving and maintaining it.  Part of the
work the tools team does includes figuring out how to make ghc and cabal more
friendly towards nix, such that we can reduce the complexity that is in haskell.nix.
