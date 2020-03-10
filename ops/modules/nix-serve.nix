{ config, lib, pkgs, ... }:
{
    services.nix-serve.enable = true;
    services.nix-serve.secretKeyFile = "/var/lib/nix-serve/nix-serve.key";
}