{ config, ... }:
{
    security.acme.email = "moritz.angermann@iohk.io";
    security.acme.acceptTerms = true;

    services.nginx = {
        enable = config.services.nginx.virtualHosts != [];
    };
}