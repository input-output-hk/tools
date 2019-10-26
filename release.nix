let
  inherit (import ./lib.nix) importPinned;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = importPinned "nixpkgs" {};

  # cross system settings
  mingwW64 = pkgs.lib.systems.examples.mingwW64;

  leksah-src = pkgs.fetchgit {
      url = "https://github.com/leksah/leksah";
      rev = "c7d90a5b2ec280431a6a0147e274a9e9a164fb58";
      sha256 = "09vi97wrzv9p2y3rxxyas18vpr3a6rlh052dim3fncgzaarzqqpj";
      fetchSubmodules = true;
    };

  leksah-mingw32 = import leksah-src { system = "x86_64-linux"; crossSystem = mingwW64; };

  # jobs contain a key -> value mapping that tells hydra which
  # derivations to build.  There are some predefined helpers in
  # https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/release
  # which can be accessed via `pkgs.releaseTools`.
  #
  # It is however not necessary to use those.
  #
  jobs = builtins.mapAttrs (_: system:
    let leksah = import leksah-src { inherit system; };
    in builtins.mapAttrs (_: pkgs.recurseIntoAttrs) {
      leksah-plan-nix = leksah.pkgs.haskell-nix.withInputs leksah.plan-nix;
    
      wrapped-leksah = leksah.wrapped-leksah;
      leksah-shells = leksah.shells;
      leksah-haskell-nix-roots = leksah.pkgs.haskell-nix.haskellNixRoots;
    }) {
      linux = "x86_64-linux";
      macos = "x86_64-darwin";
    };
in
  jobs
