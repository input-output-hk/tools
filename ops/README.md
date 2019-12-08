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
   They can be found on the agent machine at `/var/lib/hercules-ci-agent/secrets/`

2. (First time) Set up the nixops deployment:

       ./deploy.sh create hercules-ci-agents-target.nix network.nix

3. Deploy:

       ./deploy.sh deploy

       If you get `ssh` issues from nixops, nuke the nixops state: `rm secrets/state.nixops` and recreate the deployment.