{
  deployment.keys = {
    "cluster-join-token.key".keyFile = ./secrets/cluster-join-token.key;
  };
  services.hercules-ci-agent.binaryCachesFile = ./secrets/binary-caches.json;
}
