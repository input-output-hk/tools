{ config, pkgs, ... }:
{
  networking.hostName = "agent";

  imports =
    [ ../modules/agent-hardware.nix
      ../modules/agent-system.nix
      ../modules/basics.nix
      ../modules/iohk-binary-cache.nix
      ../modules/hercules-ci.nix
      ../modules/users.nix
    ];
}
