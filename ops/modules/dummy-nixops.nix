{ config, pkgs, ... }:

{
  options = with pkgs.lib; {
    deployment.keys = mkOption {
      default = {};
      type = types.unspecified;
    };
  };
}
