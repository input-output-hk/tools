let
  inherit (import ./lib.nix) importPinned;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = importPinned "nixpkgs" {};

  # cross system settings
  mingwW64 = pkgs.lib.systems.examples.mingwW64;

  leksah-src = pkgs.fetchgit {
      url = "https://github.com/leksah/leksah";
      rev = "bb7fbce75c18e21ca09ce6809bb2f141d2749f42";
      sha256 = "1lr3qgz5k837vcqj2h5788mrpzm7siqdgqbxchzaj8f4sqjxm5fn";
      fetchSubmodules = true;
    };

  leksah-mingw32 = import leksah-src { system = "x86_64-linux"; crossSystem = mingwW64; };

  # jobs contain a key -> value mapping that tells hydra which
  # derivations to build.  There are some predefined helpers in
  # https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/release
  # which can be accessed via `pkgs.releaseTools`.
  #
  # It is however not necessary to use those.
  #
  jobs = builtins.mapAttrs (_: args:
    let leksah = import leksah-src args;
    in builtins.mapAttrs (_: pkgs.recurseIntoAttrs) {
      leksah-plan-nix = leksah.pkgs.haskell-nix.withInputs leksah.plan-nix;
    
      wrapped-leksah = leksah.wrapped-leksah;
      leksah-shells = leksah.shells;
      leksah-haskell-nix-roots = leksah.pkgs.haskell-nix.haskellNixRoots;
    }) {
      linux-ghc865 = { system = "x86_64-linux"; haskellCompiler = "ghc865"; };
      linux-ghc881 = { system = "x86_64-linux"; haskellCompiler = "ghc881"; };
      macos-ghc865 = { system = "x86_64-darwin"; haskellCompiler = "ghc865"; };
      macos-ghc881 = { system = "x86_64-darwin"; haskellCompiler = "ghc881"; };
    };
in
  jobs
