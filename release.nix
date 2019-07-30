let
  inherit (import ./lib.nix) importPinned;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = importPinned "nixpkgs" {};

  # cross system settings
  mingwW64 = pkgs.lib.systems.examples.mingwW64;
  asterius32 = pkgs.lib.systems.examples.asterius32;

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

  asterius-git = pkgs.fetchgit {
      url = "https://github.com/input-output-hk/asterius";
      rev = "6f91ec6b446e81a97e8d09bdabb28207bfd15083";
      sha256 = "0qgpbb4cy4yvq0lzbx135a39xmrvyryy9zk9gyncvhpa5ib2npva";
      fetchSubmodules = true;
    };
    
  asterius = import asterius-git { inherit config; system = "x86_64-linux"; };
  asterius-macos = import asterius-git { inherit config; system = "x86_64-darwin"; };
  asterius-release = import (asterius-git + "/release.nix") { inherit config; };

  wasm = importPinned "iohk-nix" {
    haskellNixJsonOverride = ./pins/haskell-nix.json;
    crossSystem = asterius32;
    nixpkgsOverlays = [
      ( self: super: {
        stdenv = super.stdenv.override {
            cc = if super.stdenv.hostPlatform != super.stdenv.buildPlatform
                      && super.stdenv.targetPlatform.isAsterius or false
                   then null
                   else super.stdenv.cc;
          };
        haskell =
          super.haskell //
            (if super.stdenv.targetPlatform.isAsterius or false
              then {
                compiler = super.haskell.compiler // {
                  ghc864 = (import asterius-git { inherit config; system = "x86_64-linux"; })
                    .nix-tools._raw.wasm-asterius-ghc;
                };
              }
              else {});
        }
      )];
  };
  
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

    asterius-plan-nix = asterius.plan-nix;
    asterius-plan-nix-macos = asterius-macos.plan-nix;
    
    asterius-boot = asterius.nix-tools._raw.asterius-boot;
    asterius-shells = asterius.shells;
    asterius-nix-tools = asterius.nix-tools._raw.haskell.nix-tools;
    asterius-ghc = asterius.nix-tools._raw.pkgs.haskell.compiler.ghc864;
    asterius-hpack = asterius.nix-tools._raw.pkgs.haskellPackages.hpack;
    asterius-cabal-install = asterius.nix-tools._raw.pkgs.cabal-install;
    asterius-rsync = asterius.nix-tools._raw.pkgs.rsync;
    asterius-git = asterius.nix-tools._raw.pkgs.git;
    asterius-nix = asterius.nix-tools._raw.pkgs.nix;
    asterius-boehmgc = asterius.nix-tools._raw.pkgs.boehmgc;
    asterius-test = asterius.nix-tools.tests.asterius;

    asterius-shells-macos = asterius-macos.shells;
    asterius-test-macos = asterius-macos.nix-tools.tests.asterius;

    hello-wasm = (((wasm.nix-tools.default-nix ({haskell, ...}: {inherit haskell;}) {
        crossSystem = { config="wasm32-asterius"; };
      }).nix-tools._raw.haskell.hackage-package {
    	name = "hello";
    	version = "1.0.0.2";
    	cabal-install = x86_64-linux.pkgs.cabal-install;
    	ghc = x86_64-linux.pkgs.haskell.compiler.ghc864;
     })).components.exes.hello;

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
