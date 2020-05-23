{
  network.description = "Hercules CI agents";

  agent = {
    imports = [ ./hosts/agent.nix ];
  };
}
