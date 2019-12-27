let
  inherit (import ./lib.nix) importPinned;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = importPinned "nixpkgs" {};

  # cross system settings
  mingwW64 = pkgs.lib.systems.examples.mingwW64;

  leksah-src = pkgs.fetchgit {
      url = "https://github.com/leksah/leksah";
      rev = "5a59e057380cc139c12b39ca0cba0953dcc3e4a4";
      sha256 = "19wjrv8xy71wjpqxq4lc7bnipcyncma64qld53x97j9dm9qsxjdz";
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
      linux-ghc865 { ssytem = "x86_64-linux"; haskellCompiler = "ghc865"; }
      linux-ghc881 { ssytem = "x86_64-linux"; haskellCompiler = "ghc881"; }
      macos-ghc865 { ssytem = "x86_64-darwin"; haskellCompiler = "ghc865"; }
      macos-ghc881 { ssytem = "x86_64-darwin"; haskellCompiler = "ghc881"; }
    };
in
  jobs
