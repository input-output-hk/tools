let
  nixpkgs = import ../nixpkgs {};
  # hercules-ci-info = nixpkgs.pkgs.lib.importJSON ../hercules-ci-agent.json;
  # hercules-ci-agent = nixpkgs.pkgs.fetchgit {
  #   inherit (hercules-ci-info) url rev sha256;
  # };

  # take latest master branch (not stable branch)
#  hercules-ci-agent = builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/05da1213155e84c4daea58076692b02d30c1d587.tar.gz";
  # this is #162 fix ifd caching
  hercules-ci-agent = builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/8fcd34913ffa9577ac5e54a9b7a5a89e5ad97b0b.tar.gz";
#  hercules-ci-agent = builtins.fetchTarball "https://github.com/hercules-ci/hercules-ci-agent/archive/hercules-ci-agent-0.5.0.tar.gz";
in

{ config, pkgs, ... }:

{
  imports = [ (hercules-ci-agent + "/module.nix") ];

  services.hercules-ci-agent.enable = true;
  services.hercules-ci-agent.concurrentTasks = 16; # Number of jobs to run

  # In case we want to build hercules-ci from the agent itself.
  nix = {
    binaryCaches = [ "https://hercules-ci.cachix.org" ];
    binaryCachePublicKeys = [ "hercules-ci.cachix.org-1:ZZeDl9Va+xe9j+KqdzoBZMFJHVQ42Uu/c/1/KMC5Lw0=" ];
  };
}
