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
      rev = "3f0d9d89a199010330f27a8b84194102b0e150ee";
      sha256 = "1xyn75f5r1qwfyd450qk6jxj08ig3czqp88xxs7pgnii1d2q9igc";
      fetchSubmodules = true;
    };
    
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
                  ghc865 = (import asterius-git { inherit config; system = "x86_64-linux"; })
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
  jobs = (builtins.mapAttrs (_: system:
    let asterius = import asterius-git { inherit system; };
    in builtins.mapAttrs (_: pkgs.recurseIntoAttrs) {
      asterius-plan-nix = asterius.plan-nix;
      asterius-plan-nix-inputs = builtins.listToAttrs (
      	builtins.map (i: { name = builtins.replaceStrings ["."] ["_"] i.name; value = pkgs.recurseIntoAttrs i; })
      	  asterius.plan-nix.nativeBuildInputs);
    
      asterius-boot = asterius.asterius-boot;
      asterius-shells = asterius.shells;
      asterius-nix-tools = asterius.pkgs.bootstrap.haskell.packages.nix-tools;
      asterius-alex-plan-nix = asterius.pkgs.bootstrap.haskell.packages.alex-project.plan-nix;
      asterius-happy-plan-nix = asterius.pkgs.bootstrap.haskell.packages.happy-project.plan-nix;
      asterius-hscolour-plan-nix = asterius.pkgs.bootstrap.haskell.packages.hscolour-project.plan-nix;
#      asterius-ghc = asterius.hsPkgs.haskell-nix.compiler.ghc865;
      asterius-hpack = asterius.hsPkgs.hpack.components.exes.hpack;
      asterius-build-hpack = asterius.pkgs.buildPackages.haskell-nix.haskellPackages.hpack.components.exes.hpack;
#      asterius-cabal-install = asterius.nix-tools._raw.pkgs.cabal-install;
#      asterius-rsync = asterius.nix-tools._raw.pkgs.rsync;
#      asterius-git = asterius.nix-tools._raw.pkgs.git;
#      asterius-nix = asterius.nix-tools._raw.pkgs.nix;
#      asterius-boehmgc = asterius.nix-tools._raw.pkgs.boehmgc;
      asterius-test = asterius.hsPkgs.asterius.components.tests;
    }) {
      linux = "x86_64-linux";
      macos = "x86_64-darwin";
    }) // {

    hello-wasm = (((wasm.nix-tools.default-nix ({haskell, ...}: {inherit haskell;}) {
        crossSystem = { config="wasm32-asterius"; };
      }).nix-tools._raw.haskell.hackage-package {
        name = "hello";
        version = "1.0.0.2";
        cabal-install = x86_64-linux.pkgs.cabal-install;
        ghc = x86_64-linux.pkgs.haskell.compiler.ghc865;
        pkg-def-extras = [
          (hackage: {
            packages.Cabal.revision = (((hackage."Cabal")."2.4.0.1").revisions).default;
          })
        ];
        modules = [
          { nonReinstallablePkgs =
             [ "ghc-boot" "binary" "bytestring" "filepath" "directory" "containers" "time" "unix" "Win32"
               "ghci" "hpc" "process" "terminfo" "transformers" "mtl" "parsec" "text"
             ];
          }
          ({config, ...}: {
            packages.hello.package.setup-depends = [config.hsPkgs.buildPackages.Cabal];
            packages.Cabal.patches = [ ./patches/Cabal.patch ];
#            packages.Cabal.src = ../../haskell/cabal/Cabal;
          }) ];
     })).components.exes.hello;

    # this should give us our patched compiler. (e.g. the one
    # from the pinned nixpkgs set with all the iohk-nix
    # patches applied.

    # linux
    ghc865.x86_64-linux = x86_64-linux.pkgs.haskell.compiler.ghc865;

    # macOS
    ghc865.x86_64-macos = x86_64-macos.pkgs.haskell.compiler.ghc865;

    # linux -> win32
    # Note: we want to build the cross-compiler. As such we want something from the buildPackages!
    "${mingwW64.config}-ghc865".x86_64-linux = x86_64-mingw32.pkgs.buildPackages.haskell.compiler.ghc865;
  };
in
  jobs
