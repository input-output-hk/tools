1. Put the secrets in `./secrets` (don't check in to git).
   They can be found on the agent machine at `/var/lib/hercules-ci-agent/secrets/`

2. (First time) Set up the nixops deployment:

       ./deploy.sh create hercules-ci-agents-target.nix network.nix

3. Deploy:

       ./deploy.sh deploy
