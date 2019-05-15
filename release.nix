let
  # generic function to fetch a tarball from a given .json file
  # like those provided in ./pins
  fetchTarballFromJson = jsonFile: with builtins;
    let spec = fromJSON (readFile jsonFile); in fetchTarball {
      inherit (spec) sha256; url = "${spec.url}/archive/${spec.rev}.tar.gz"; };

  # Allow overriding the fetch with a name on the command line so we can use -I
  fetchTarballFromJsonWithOverride = override: srcJson: with builtins;
    let try = tryEval (findFile nixPath override); in
    if try.success then trace "using search host <${override}>" try.value
    else fetchTarballFromJson srcJson;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = import (fetchTarballFromJsonWithOverride "nixpkgs" ./pins/nixpkgs-src.json) {};

  # jobs contain a key -> value mapping that tells hydra which
  # derivations to build.  There are some predefined helpers in
  # https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/release
  # which can be accessed via `pkgs.releaseTools`.
  #
  # It is however not necessary to use those.
  #
  jobs = rec {
    # a very simple job. All it does is call a shell script that print Hello World.
    hello-world = derivation {
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
    };
  };

in
  jobs
