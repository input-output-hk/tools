let
  arm-test = import ./arm-test {};
  x86_64-darwin-arm-test = import ./arm-test { system = "x86_64-darwin"; };
  aarch64-darwin-arm-test = import ./arm-test { system = "aarch64-darwin"; };

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

    inherit arm-test;

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

    # ogmios.aarch64                          = arm-test.rpi64-musl.ogmios-tarball;
  };
in
  jobs
