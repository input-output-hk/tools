let
  inherit (import ./lib.nix) importPinned;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = importPinned "nixpkgs" {};

  # cross system settings
  mingwW64 = pkgs.lib.systems.examples.mingwW64;

  # import iohk-nix with the same pin as the nixpkgs above.
  config = { allowUnfree = false; inHydra = true; allowUnsupportedSystem = true; };

  # linux packages
  x86_64-linux = importPinned "iohk-nix"
    { inherit config; nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-linux"; };

  # macos packages
  x86_64-macos = importPinned "iohk-nix"
    { inherit config; nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-darwin"; };

  # windows cross compiled on linux
  x86_64-mingw32 = importPinned "iohk-nix"
    { inherit config; nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-linux"; crossSystem = mingwW64; };

  leksah = import (pkgs.fetchgit {
      url = "https://github.com/leksah/leksah";
      rev = "2f9c8b1c04bc242b03736afc89af1cf086f95e33";
      sha256 = "1v4vydqqhx1vjrqy7bassygzdpvgd9k255k63dxq2zvklw59r83r";
      fetchSubmodules = true;
    }+ "/default.nix") {};
    
  # jobs contain a key -> value mapping that tells hydra which
  # derivations to build.  There are some predefined helpers in
  # https://github.com/NixOS/nixpkgs/tree/master/pkgs/build-support/release
  # which can be accessed via `pkgs.releaseTools`.
  #
  # It is however not necessary to use those.
  #
  jobs = rec {
    # a very simple job. All it does is call a shell script that print Hello World.
    hello-world = import ./jobs/trivial-hello-world { inherit pkgs; };

    # wrapped-leksah = leksah.nix-tools._raw.wrapped-leksah;

    # this should give us our patched compiler. (e.g. the one
    # from the pinned nixpkgs set with all the iohk-nix
    # patches applied.

    # linux
    ghc865.x86_64-linux = x86_64-linux.pkgs.haskell.compiler.ghc865;

    # macOS
    ghc865.x86_64-macos = x86_64-macos.pkgs.haskell.compiler.ghc865;

    # linux -> win32
    # Note: we want to build the cross-compiler. As such we want something from the buildPackages!
    "${mingwW64.config}-ghc865".x86_64-linux = x86_64-mingw32.pkgs.buildPackages.haskell.compiler.ghc865;
  };
in
  jobs
