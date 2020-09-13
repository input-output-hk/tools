# This is a sample NixOS configuration file which you can import into
# your own configuration.nix in order to enable the IOHK binary cache.

{ config, lib, pkgs, ... }:

{
  nix = {
    binaryCachePublicKeys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ=" "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo=" ];
    binaryCaches = [ "https://hydra.iohk.io" "iohk.cachix.org" ];
  };
}
