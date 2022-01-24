let
  inherit (import ./lib.nix) importPinned;

  arm-test = import ./arm-test {};
  x86_64-darwin-arm-test = import ./arm-test { system = "x86_64-darwin"; };
  aarch64-darwin-arm-test = import ./arm-test { system = "aarch64-darwin"; };

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

  # jobs contain a key -> value mapping that tells hydra which
  # derivations to build.  There are some predefined helpers in
  # https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/release
  # which can be accessed via `pkgs.releaseTools`.
  #
  # It is however not necessary to use those.
  #
  jobs = rec {
    # a very simple job. All it does is call a shell script that print Hello World.
    # hello-world = import ./jobs/trivial-hello-world { inherit pkgs; };

    # this should give us our patched compiler. (e.g. the one
    # from the pinned nixpkgs set with all the iohk-nix
    # patches applied.

    # linux
    # ghc864.x86_64-linux = x86_64-linux.pkgs.haskell.compiler.ghc864;

    # macOS
    # ghc864.x86_64-macos = x86_64-macos.pkgs.haskell.compiler.ghc864;

    # linux -> win32
    # Note: we want to build the cross-compiler. As such we want something from the buildPackages!
    # "${mingwW64.config}-ghc864".x86_64-linux = x86_64-mingw32.pkgs.buildPackages.haskell.compiler.ghc864;

    cardano-node.x86_64-linux-gnu          = arm-test.native.cardano-node.mainnet.tarball;
    cardano-node.x86_64-apple-darwin       = x86_64-darwin-arm-test.native.cardano-node.mainnet.tarball;
    cardano-node.aarch64-apple-darwin      = aarch64-darwin-arm-test.native.cardano-node.mainnet.tarball;

    cardano-node.x86_64-linux-musl         = arm-test.x86-musl64.cardano-node.mainnet.tarball;
    cardano-node.x86_64-windows            = arm-test.x86-win64.cardano-node.mainnet.tarball;

    cardano-node.aarch64-linux-musl        = arm-test.rpi64-musl.cardano-node.mainnet.tarball;

    cardano-node.js-ghcjs                  = arm-test.ghcjs.cardano-node.mainnet.tarball;
    cardano-node.aarch64-android           = arm-test.aarch64-android.cardano-node.mainnet.tarball;
    cardano-node-capi.aarch64-android      = arm-test.aarch64-android.cardano-node.mainnet.cardano-node-capi;

    cardano-wallet-musl.aarch64-linux-musl = arm-test.rpi64-musl.cardano-node.mainnet.cardano-wallet;

    cardano-node-syno-spk.aarch64           = arm-test.rpi64-musl.cardano-node.mainnet.cardano-node-spk;
    cardano-node-syno-spk.x86_64            = arm-test.x86-musl64.cardano-node.mainnet.cardano-node-spk;
    cardano-submit-api-syno-spk.aarch64     = arm-test.rpi64-musl.cardano-node.mainnet.cardano-submit-api-spk;
    cardano-submit-api-syno-spk.x86_64      = arm-test.x86-musl64.cardano-node.mainnet.cardano-submit-api-spk;
  };
in
  jobs
