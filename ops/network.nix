{
  network.description = "Tools Builder";

  x86_64-builder = {
    imports = [ ./hosts/x86_64-builder.nix ];
  };

  aarch64-builder = {
    imports = [ ./hosts/aarch64-builder.nix ];
  };
}
