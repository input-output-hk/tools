{ config, ... }:
{
    services.nginx.virtualHosts."cache.loony-tools.dev.iohkdev.io" = {
        enableACME = true;
        locations."/".extraConfig = ''
            proxy_pass http://localhost:${toString config.services.nix-serve.port};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
    };
}