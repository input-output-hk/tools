{ config, pkgs, ... }:
{
  networking.hostName = "x86_64-builder";
  nixpkgs.overlays =
    [
        (import ../overlays/mosh.nix)
    ];

  imports =
    [ ../modules/hetzner/EX62-NVMe/default.nix

      ../modules/common.nix
      ../modules/web-service-nix-cache.nix

    ];
}
