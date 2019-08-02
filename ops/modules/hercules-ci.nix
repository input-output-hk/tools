let
  nixpkgs = import ../nixpkgs {};
  # hercules-ci-info = nixpkgs.pkgs.lib.importJSON ../hercules-ci-agent.json;
  # hercules-ci-agent = nixpkgs.pkgs.fetchgit {
  #   inherit (hercules-ci-info) url rev sha256;
  # };

  # take latest master branch (not stable branch)
  hercules-ci-agent = builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/master.tar.gz";
in

{ config, pkgs, ... }:

{
  imports = [ (hercules-ci-agent + "/module.nix") ];

  services.hercules-ci-agent.enable = true;
  services.hercules-ci-agent.concurrentTasks = 4; # Number of jobs to run
}
