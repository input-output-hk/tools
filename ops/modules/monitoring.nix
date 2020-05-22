{ config, pkgs, ... }:
{
    services.prometheus.exporters = {
        nginx = {
            enable = config.services.nginx.enable;
            openFirewall = config.services.nginx.enable;
        };
        node = {
            enable = true;
            openFirewall = true;
        };
    };
}