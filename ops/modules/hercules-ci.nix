let
  nixpkgs = import ../nixpkgs {};
  hercules-ci-info = nixpkgs.pkgs.lib.importJSON ../hercules-ci-agent.json;
  hercules-ci-agent = nixpkgs.pkgs.fetchgit {
    inherit (hercules-ci-info) url rev sha256;
  };
in

{ config, pkgs, ... }:

{
  imports = [ (hercules-ci-agent + "/module.nix") ];

  services.hercules-ci-agent.enable = true;
  services.hercules-ci-agent.concurrentTasks = 4; # Number of jobs to run
}
