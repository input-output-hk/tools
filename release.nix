let
  inherit (import ./lib.nix) importPinned;

  # fetch nixpkgs. iohk hydra doesn't provide <nixpkgs>, so we'll have to use
  # a pinned one.
  pkgs = importPinned "nixpkgs" {};

  # cross system settings
  mingwW64 = pkgs.lib.systems.examples.mingwW64;

  # import iohk-nix with the same pin as the nixpkgs above.

  # linux packages
  x86_64-linux = importPinned "iohk-nix"
    { nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-linux"; };

  # macos packages
  x86_64-macos = importPinned "iohk-nix"
    { nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-darwin"; };

  # windows cross compiled on linux
  x86_64-mingw32 = importPinned "iohk-nix"
    { nixpkgsJsonOverride = ./pins/nixpkgs-src.json; system = "x86_64-linux"; crossSystem = mingwW64; };

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

    # this should give us our patched compiler. (e.g. the one
    # from the pinned nixpkgs set with all the iohk-nix
    # patches applied.

    # linux
    ghc864.x86_64-linux = x86_64-linux.pkgs.haskell.compiler.ghc864;

    # macOS
    ghc864.x86_64-macos = x86_64-macos.pkgs.haskell.compiler.ghc864;

    # linux -> win32
    "${mingwW64.config}-ghc864".x86_64-linux = x86_64-mingw32.pkgs.haskell.compiler.ghc864;

  };
in
  jobs
