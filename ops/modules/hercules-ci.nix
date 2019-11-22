let
  nixpkgs = import ../nixpkgs {};
  # hercules-ci-info = nixpkgs.pkgs.lib.importJSON ../hercules-ci-agent.json;
  # hercules-ci-agent = nixpkgs.pkgs.fetchgit {
  #   inherit (hercules-ci-info) url rev sha256;
  # };

  # take latest master branch (not stable branch)
  # hercules-ci-agent = builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/ba2a097e1c89266357b0052d342a07f259b20ff0.tar.gz";
  hercules-ci-agent = builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/stable.tar.gz";
in

{ config, pkgs, ... }:

{
  imports = [ (hercules-ci-agent + "/module.nix") ];

  services.hercules-ci-agent.enable = true;
  services.hercules-ci-agent.concurrentTasks = 2; # Number of jobs to run

  # In case we want to build hercules-ci from the agent itself.
  nix = {
    binaryCaches = [ "https://hercules-ci.cachix.org" ];
    binaryCachePublicKeys = [ "hercules-ci.cachix.org-1:ZZeDl9Va+xe9j+KqdzoBZMFJHVQ42Uu/c/1/KMC5Lw0=" ];
  };
}
