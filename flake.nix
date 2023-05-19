{
    inputs = {
        haskell-nix.url = "github:input-output-hk/haskell.nix";
        iohk-nix.url = "github:input-output-hk/iohk-nix";
        nixpkgs.follows = "haskell-nix/nixpkgs";
        bech32.url = "github:input-output-hk/bech32";
        bech32.flake = false;
        cardano-node-mainnet.url = "github:input-output-hk/cardano-node?ref=8.0.0";
        cardano-node-mainnet.flake = false;
        cardano-haskell-packages.url = "github:input-output-hk/cardano-haskell-packages?ref=repo";
        cardano-haskell-packages.flake = false;
    };
    outputs = inputs:
        let
          arm-test = import ./arm-test inputs {};
          x86_64-darwin-arm-test = (import ./arm-test inputs) { system = "x86_64-darwin"; };
          aarch64-darwin-arm-test = (import ./arm-test inputs) { system = "aarch64-darwin"; };
        in { hydraJobs = {
            cardano-node.x86_64-linux-gnu          = arm-test.native.cardano-node.mainnet.tarball;
            cardano-node.x86_64-apple-darwin       = x86_64-darwin-arm-test.native.cardano-node.mainnet.tarball;
            cardano-node.aarch64-apple-darwin      = aarch64-darwin-arm-test.native.cardano-node.mainnet.tarball;

            cardano-node.x86_64-linux-musl         = arm-test.x86-musl64.cardano-node.mainnet.tarball;
            cardano-node.x86_64-windows            = arm-test.x86-win64.cardano-node.mainnet.tarball;

            cardano-node.aarch64-linux-musl        = arm-test.rpi64-musl.cardano-node.mainnet.tarball;

            cardano-node.js-ghcjs                  = arm-test.ghcjs.cardano-node.mainnet.tarball;
            cardano-node.aarch64-android           = arm-test.aarch64-android.cardano-node.mainnet.tarball;
            # cardano-node-capi.aarch64-android      = arm-test.aarch64-android.cardano-node.mainnet.cardano-node-capi;

            # cardano-wallet-musl.aarch64-linux-musl = arm-test.rpi64-musl.cardano-node.mainnet.cardano-wallet;

            cardano-node-syno-spk.aarch64           = arm-test.rpi64-musl.cardano-node.mainnet.cardano-node-spk;
            cardano-node-syno-spk.x86_64            = arm-test.x86-musl64.cardano-node.mainnet.cardano-node-spk;
            cardano-submit-api-syno-spk.aarch64     = arm-test.rpi64-musl.cardano-node.mainnet.cardano-submit-api-spk;
            cardano-submit-api-syno-spk.x86_64      = arm-test.x86-musl64.cardano-node.mainnet.cardano-submit-api-spk;
        };
    };
}