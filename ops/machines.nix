{ pkgs ? import ./nixpkgs/default.nix {} }:
let
  mkMachine = configuration: (import (pkgs.path + /nixos) {
    system = "x86_64-linux";
    inherit configuration;
  }).system;

in {
  agent = mkMachine {
    imports = [ ./hosts/agent.nix ./modules/dummy-nixops.nix ];
    deployment.keys."cluster-join-token.key".keyFile = /dev/null;
#    services.hercules-ci-agent.binaryCachesFile = builtins.toFile "binary-caches.json" (builtins.toJSON {});
  };
}
