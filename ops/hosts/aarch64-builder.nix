{ config, pkgs, ... }:
{
  networking.hostName = "aarch64-builder";
  nixpkgs.overlays =
    [
        (import ../overlays/mosh.nix)
    ];

  imports =
    [ ../modules/packet/c2.large.arm/default.nix

      ../modules/common.nix
    ];
}
