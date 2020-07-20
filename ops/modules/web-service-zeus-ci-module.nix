{ config, lib, pkgs, ... }:
with lib;
let
    cfg = config.services.zeus;

    defaultUser = "zeus-ci-agent";
    defaultUserDetails = {
      name = defaultUser;
      home = "/var/lib/zeus-ci-agent";
      description = "System user for the zeus-ci service";
      isSystemUser = true;
      createHome = true;
    };
in {
    options.services.zeus = {
        enable = mkOption {
            type = types.bool;
            default = false;
            description = "If enabled, run zeus-ci service";
        };
        user = mkOption {
            description = "Unix system user that runs the hokey-pokey service";
            type = types.str;
        };
    };
    config = mkIf cfg.enable {
        services.zeus.user = mkDefault defaultUser;

        systemd.services.zeus = {
            enable = true;
            wantedBy = [ "multi-user-target" ];
            after = [ "network-online.target" ];
            serviceConfig = {
                Restart = "always";
                RestartSec = 10;
                ExecStart = "${(import (import ../nix/sources.nix {}).zeus { inherit (pkgs) system; }).exe}/backend -p 8000 +RTS -N";
                User = cfg.user;
                WorkingDirectory = config.users.users.${cfg.user}.home;
                StandardOutput = "journal+console";
                StandardError = "journal+console";
            };
        };
        users = mkIf (cfg.user == defaultUser) {
            users.zeus-ci-agent = defaultUserDetails;
        };
    };
}