0. Setup the server.  We use a hetzner server with two nvme disks.
   Boot the system into recovery mode and execute
   ```
   ssh root@88.99.0.251 "$(< hetzner-dedicated-wipe-and-install-nixos.sh)"
   ```
   (after adjusting the ssh pub key).

   Copy the contents of `/etc/nixos/hardware-configuration.nix` into `modules/agent-hardware.nix` and add
   ```
     boot.supportedFilesystems = [ "zfs" ];
     networking.hostId = "eca0dea2"; # required for zfs use
   ```
   to the `agent-hardware.nix`. Where the `networking.hostId` is from `/etc/nixos/configuration.nix` on the server.

1. Put the secrets in `./secrets` (don't check in to git).
   They can be found on the agent machine at `/var/lib/hercules-ci-agent/secrets/` and `/var/lib/nix-serve/`
   ```
   scp root@88.99.0.251:"/var/lib/hercules-ci-agent/secrets/*" secrets
   scp root@88.99.0.251:"/var/lib/nix-serve/*" secrets
   ```

2. (First time) Set up the nixops deployment:
   ```
   ./deploy.sh create x86_64-builder.nix aarch64-builder.nix network.nix
   ```

3. Deploy:
   ```
   ./deploy.sh deploy
   ```
   from macOS, you likely want something like:
   ```
   ./deploy.sh deploy --option builders "ssh://root@88.99.0.251 x86_64-linux $HOME/.ssh/id_rsa 16 5" --option builders-use-substitutes true --cores 0
   ```

   Note: *If you get `ssh` issues from nixops, nuke the nixops state: `rm secrets/state.nixops` and recreate the deployment.*
