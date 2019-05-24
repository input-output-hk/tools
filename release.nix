let
  inherit (import ./lib.nix) importPinned;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = importPinned "nixpkgs" {};

  # cross system settings
  mingwW64 = pkgs.lib.systems.examples.mingwW64;

  # import iohk-nix with the same pin as the nixpkgs above.
  config = { allowUnfree = false; inHydra = true; allowUnsupportedSystem = true; };

  # linux packages
  x86_64-linux = importPinned "iohk-nix"
    { inherit config; nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-linux"; };

  # macos packages
  x86_64-macos = importPinned "iohk-nix"
    { inherit config; nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-darwin"; };

  # windows cross compiled on linux
  x86_64-mingw32 = importPinned "iohk-nix"
    { inherit config; nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-linux"; crossSystem = mingwW64; };

  asterius = import (pkgs.fetchgit {
      url = "https://github.com/input-output-hk/asterius";
      rev = "b939a8e63d71a63450605bb8d26ce247e7e16157";
      sha256 = "12ykihra6siy87snvax4pq5m4d4d5iyjxyd6rn0fpi9j4lbglnrj";
      fetchSubmodules = true;
    }) {};
    
  # jobs contain a key -> value mapping that tells hydra which
  # derivations to build.  There are some predefined helpers in
  # https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/release
  # which can be accessed via `pkgs.releaseTools`.
  #
  # It is however not necessary to use those.
  #
  jobs = rec {
    # a very simple job. All it does is call a shell script that print Hello World.
    hello-world = import ./jobs/trivial-hello-world { inherit pkgs; };

    asterius-boot = asterius.nix-tools._raw.asterius-boot;
    asterius-plan-nix = asterius.nix-tools._raw.plan-nix;
    asterius-nix-tools = asterius.nix-tools._raw.haskell.nix-tools;
    asterius-ghc = asterius.nix-tools._raw.pkgs.haskell.compiler.ghc864;
    asterius-hpack = asterius.nix-tools._raw.pkgs.haskellPackages.hpack;
    asterius-cabal-install = asterius.nix-tools._raw.pkgs.cabal-install;
    asterius-rsync = asterius.nix-tools._raw.pkgs.rsync;
    asterius-git = asterius.nix-tools._raw.pkgs.git;
    asterius-nix = asterius.nix-tools._raw.pkgs.nix;
    asterius-boehmgc = asterius.nix-tools._raw.pkgs.boehmgc;    

    # this should give us our patched compiler. (e.g. the one
    # from the pinned nixpkgs set with all the iohk-nix
    # patches applied.

    # linux
    ghc864.x86_64-linux = x86_64-linux.pkgs.haskell.compiler.ghc864;

    # macOS
    ghc864.x86_64-macos = x86_64-macos.pkgs.haskell.compiler.ghc864;

    # linux -> win32
    # Note: we want to build the cross-compiler. As such we want something from the buildPackages!
    "${mingwW64.config}-ghc864".x86_64-linux = x86_64-mingw32.pkgs.buildPackages.haskell.compiler.ghc864;
  };
in
  jobs
