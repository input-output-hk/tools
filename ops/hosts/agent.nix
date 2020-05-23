{ config, pkgs, ... }:
{
  networking.hostName = "loony-tools-agent";

  imports =
    [ ../modules/agent-hardware.nix
      ../modules/agent-system.nix
      ../modules/basics.nix
      ../modules/iohk-binary-cache.nix
      ../modules/nix-serve.nix
      ../modules/users.nix
      ../modules/web-services.nix
      ../modules/web-service-nix-cache.nix
    #  ../modules/web-service-hokey-pokey.nix
      ../modules/monitoring.nix
    ];
}
