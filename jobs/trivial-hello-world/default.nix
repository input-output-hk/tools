# A very trivial derivation.  All it does is write "Hello World" into
# a file called `hello`.
#
# It also showcases how to add the nix-support/hydra-build-products
# file to make hydra provide the `hello` file as a downloadable artifact.
#
{ pkgs }:

derivation {
  name = "hello-world";
  builder = "${pkgs.bash}/bin/bash";
  args = [
    (pkgs.writeScript "helloWorld.sh"
      ''
      ${pkgs.coreutils}/bin/mkdir $out
      echo "Hello World" > $out/hello

      # this will allow us to download the "test"
      # build artifact from hydra. Note the special
      # $out/nix-support folder and the
      # hydra-build-products file.
      #
      # For the list of supported types see
      # https://github.com/nixos/hydra/blob/master/src/root/product-list.tt
      #
      ${pkgs.coreutils}/bin/mkdir -p $out/nix-support
      echo "file binary-dist \"$out/hello\"" \
        > $out/nix-support/hydra-build-products
      '')
   ];
  system = builtins.currentSystem;
}
