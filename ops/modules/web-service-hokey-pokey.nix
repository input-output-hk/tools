let
  # hokey-pokey webservice
  hokey-pokey = builtins.fetchTarball {
    url = "https://github.com/input-output-hk/hokey-pokey/archive/a092b18.tar.gz";
    # nix-prefetch-url --unpack https://github.com/input-output-hk/hokey-pokey/archive/a092b18.tar.gz
    sha256 = "0n9gwhis5d290vwljwxqmbbvh9npvs0s5wnqrcnx6i355rh5v20p";
  };
in

{ config, pkgs, ... }:
{
    imports = [ (hokey-pokey + "/module.nix") ];

    services.hokey-pokey.enable = true;

    services.nginxvirtualHosts."hokey-pokey.loony-tools.dev.iohkdev.io" = {
        enableACME = true;
        default = true;
        locations."/".proxyPass = "http://127.0.0.1:8080";
        basicAuthFile = ../secrets/hokey-pokey-auth.htpasswd;
        # proxyWebsockets = true;
    };
}