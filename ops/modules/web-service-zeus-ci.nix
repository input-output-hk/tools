# So this is their instructions...
# git clone https://github.com/mightybyte/zeus.git
# cd zeus
# nix-build -A exe -o result-exe
# mkdir -p config/common
# echo http://localhost:8000 > config/common/route
# result-exe/backend -p 8000 +RTS -N
{ config, lib, pkgs, ... }:
{
    imports = [ ./web-service-zeus-ci-module.nix ];

    services.zeus.enable = true;

    services.nginx.virtualHosts."ci.loony-tools.dev.iohkdev.io" = {
        enableACME = true;
        default = true;
        locations."/static/".alias = "${(import (import ../nix/sources.nix {}).zeus { inherit (pkgs) system; }).exe}/static.assets/";
        locations."/ghcjs/".alias = "${(import (import ../nix/sources.nix {}).zeus { inherit (pkgs) system; }).exe}/frontend.jsexe.assets/";
        locations."/".proxyPass = "http://0.0.0.0:8000";
    };

}