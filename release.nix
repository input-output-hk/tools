let
  pkgs = import <nixpkgs> {};

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
      name = "Hello World";
      builder = pkgs.writeShellScriptBin "helloWorld" "echo Hello World";
      system = builtins.currentSystem;
    };
    
  };
in
  jobs
