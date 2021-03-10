let
  sources = import ./nix/sources.nix {};
  # Fetch the latest haskell.nix and import its default.nix
  haskellNix = import sources."haskell.nix" {};
  # haskell.nix provides access to the nixpkgs pins which are used by our CI, hence
  # you will be more likely to get cache hits when using these.
  # But you can also just use your own, e.g. '<nixpkgs>'
  nixpkgsSrc = import sources.nixpkgs-m1; #haskellNix.sources.nixpkgs-2009; #sources.nixpkgs; #
  # haskell.nix provides some arguments to be passed to nixpkgs, including some patches
  # and also the haskell.nix functionality itself as an overlay.
  nixpkgsArgs = haskellNix.nixpkgsArgs;
in
{ system ? __currentSystem
, nativePkgs ? import nixpkgsSrc (nixpkgsArgs // { overlays =
    # [ (import ./rust.nix)] ++
    nixpkgsArgs.overlays ++
    [(final: prev: { libsodium = final.callPackage ./libsodium.nix {}; })]
    ;
    inherit system;
    })
, haskellCompiler ? "ghc8104"
, cardano-node-info ? sources.cardano-node
, cardano-node-src ? nativePkgs.fetchgit { inherit (cardano-node-info) url rev sha256; }
# , cardano-rt-view-json
# , cardano-rt-view-info ? __fromJSON (__readFile cardano-rt-view-json)
# , cardano-rt-view-src ? nativePkgs.fetchgit (removeAttrs cardano-rt-view-info [ "date" ])
# , wstunnel-json
# , wstunnel-info ? __fromJSON (__readFile wstunnel-json)
# , wstunnel-src ? nativePkgs.fetchgit (removeAttrs wstunnel-info [ "date" ])
# , ghcup-src ? ./ghcup-hs
}:
let toBuild = with nativePkgs.pkgsCross; {
  # x86-gnu32 = gnu32;
  native = nativePkgs; #gnu64; # should be == nativePkgs
  # x86-musl32 = musl32;
  x86-musl64 = musl64;
  x86-win64 = mingwW64;
  rpi1-gnu = raspberryPi;
  rpi1-musl = muslpi;
  rpi32-gnu = armv7l-hf-multiplatform;
  # sadly this one is missing from the nixpkgs system examples
  rpi32-musl = import nixpkgsSrc (nativePkgs.lib.recursiveUpdate nixpkgsArgs
    { crossSystem = nativePkgs.lib.systems.examples.armv7l-hf-multiplatform
                  // { config = "armv7l-unknown-linux-musleabihf"; }; });
  rpi64-gnu = aarch64-multiplatform;
  rpi64-musl = aarch64-multiplatform-musl;
}; in
# 'cabalProject' generates a package set based on a cabal.project (and the corresponding .cabal files)
nativePkgs.lib.mapAttrs (_: pkgs: rec {
  # nativePkgs.lib.recurseIntoAttrs, just a bit more explicilty.
  recurseForDerivations = true;

  hello = (pkgs.haskell-nix.hackage-package {
      name = "hello";
      version = "1.0.0.2";
      ghc = pkgs.buildPackages.pkgs.haskell-nix.compiler.${haskellCompiler};
    }).components.exes.hello;

  cabal-install = (pkgs.haskell-nix.hackage-package {
      name = "cabal-install";
      # can't build 3.0 or 3.2, we seem to pass in the lib Cabal from our GHC :-/
      version = "3.2.0.0";
      ghc = pkgs.buildPackages.pkgs.haskell-nix.compiler.${haskellCompiler};

      modules = [
        # haddock can't find haddock m(
        { doHaddock = false; }
        # lukko breaks hsc2hs
        { packages.lukko.patches = [ ./cabal-install-patches/19.patch ]; }
        # Remove Cabal from nonReinstallablePkgs to be able to pick Cabal-3.2.
        { nonReinstallablePkgs = [
          "rts" "ghc-heap" "ghc-prim" "integer-gmp" "integer-simple" "base"
          "deepseq" "array" "ghc-boot-th" "pretty" "template-haskell"
          # ghcjs custom packages
          "ghcjs-prim" "ghcjs-th"
          "ghc-boot"
          "ghc" "Win32" "array" "binary" "bytestring" "containers"
          "directory" "filepath" "ghc-boot" "ghc-compact" "ghc-prim"
          # "ghci" "haskeline"
          "hpc"
          "mtl" "parsec" "process" "text" "time" "transformers"
          "unix" "xhtml"
          # "stm" "terminfo"
        ]; }
      ];
    }).components.exes.cabal;

  # __ghcup = (pkgs.haskell-nix.cabalProject {
  #     compiler-nix-name = haskellCompiler;
  #     src = ghcup-src;


  #     configureArgs = "--disable-tests";

  #     modules = [
  #       { doHaddock = false; }
  #     ];
  # });


  # __cardano-db-sync = (pkgs.haskell-nix.cabalProject {
  #     compiler-nix-name = haskellCompiler;
  #     # pkgs.haskell-nix.haskellLib.cleanGit { name = "cardano-node"; src = ... } <- this doesn't work with fetchgit results
  #     src = ./cardano-db-sync;
  #     modules = [
  #       { doHaddock = false; }
  #       { compiler.nix-name = haskellCompiler; }
  #       { packages.cardano-config.flags.systemd = false;
  #         packages.cardano-node.flags.systemd = false; }

  #     ];
  # });

  __cardano-node = (pkgs.haskell-nix.cabalProject {
      compiler-nix-name = haskellCompiler;
      # pkgs.haskell-nix.haskellLib.cleanGit { name = "cardano-node"; src = ... } <- this doesn't work with fetchgit results
      src = cardano-node-src;
      # ghc = pkgs.buildPackages.pkgs.haskell-nix.compiler.${haskellCompiler};
      modules = [
        # Allow reinstallation of Win32
        { nonReinstallablePkgs =
          [ "rts" "ghc-heap" "ghc-prim" "integer-gmp" "integer-simple" "base"
            "deepseq" "array" "ghc-boot-th" "pretty" "template-haskell"
            # ghcjs custom packages
            "ghcjs-prim" "ghcjs-th"
            "ghc-boot"
            "ghc" "array" "binary" "bytestring" "containers"
            "filepath" "ghc-boot" "ghc-compact" "ghc-prim"
            # "ghci" "haskeline"
            "hpc"
            "mtl" "parsec" "text" "transformers"
            "xhtml"
            # "stm" "terminfo"
          ];
        }
        # haddocks are useless (lol);
        # and broken for cross compilers!
        { doHaddock = false; }
        { compiler.nix-name = haskellCompiler; }
        { packages.cardano-config.flags.systemd = false;
          packages.cardano-node.flags.systemd = false; }
        { packages.terminal-size.patches = [ ./cardano-node-patches/terminal-size-0.3.2.1.patch ];
          packages.unix-bytestring.patches = [ ./cardano-node-patches/unix-bytestring-0.3.7.3.patch ];
          # packages.typerep-map.patches = [ ./cardano-node-patches/typerep-map-PR82.patch ];
          # packages.streaming-bytestring.patches = [ ./cardano-node-patches/streaming-bytestring-0.1.6.patch ];
          # packages.byron-spec-ledger.patches = [ ./cardano-node-patches/byron-ledger-spec-no-goblins.patch ];
          packages.byron-spec-ledger.flags.goblins = false;
          # this one will disable gitRev; which fails (due to a linker bug) for armv7
          # packages.cardano-config.patches = [ ./cardano-node-patches/1036.patch ];

          # Disable cabal-doctest tests by turning off custom setups
          packages.comonad.package.buildType = nativePkgs.lib.mkForce "Simple";
          packages.distributive.package.buildType = nativePkgs.lib.mkForce "Simple";
          packages.lens.package.buildType = nativePkgs.lib.mkForce "Simple";
          packages.nonempty-vector.package.buildType = nativePkgs.lib.mkForce "Simple";
          packages.semigroupoids.package.buildType = nativePkgs.lib.mkForce "Simple";

          # Remove hsc2hs build-tool dependencies (suitable version will be available as part of the ghc derivation)
          packages.Win32.components.library.build-tools = nativePkgs.lib.mkForce [];
          packages.terminal-size.components.library.build-tools = nativePkgs.lib.mkForce [];
          packages.network.components.library.build-tools = nativePkgs.lib.mkForce [];
        }
      ];
    });

    # __cardano-rt-view = (pkgs.haskell-nix.cabalProject {
    #   compiler-nix-name = haskellCompiler;
    #   src = cardano-rt-view-src;
    #   modules = [];
    # });

    # __wstunnel = (pkgs.haskell-nix.cabalProject {
    #   compiler-nix-name = haskellCompiler;
    #   src = wstunnel-src;
    #   modules = [{ dontStrip = false; }];
    # });

    inherit (__cardano-node.cardano-node.components.exes) cardano-node;
    inherit (__cardano-node.cardano-cli.components.exes)  cardano-cli;

    # inherit (__cardano-rt-view.cardano-rt-view.components.exes) cardano-rt-view;

    # inherit (__wstunnel.wstunnel.components.exes) wstunnel;

    # inherit (__ghcup.ghcup.components.exes) ghcup;

    # wstunnel-tarball = nativePkgs.stdenv.mkDerivation {
    #   name = "${pkgs.stdenv.targetPlatform.config}-tarball";
    #   buildInputs = with nativePkgs; [ patchelf zip ];

    #   phases = [ "buildPhase" "installPhase" ];
    #   buildPhase = ''
    #     mkdir -p wstunnel
    #     cp ${wstunnel}/bin/*wstunnel* wstunnel/
    #   '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && !pkgs.stdenv.targetPlatform.isMusl) ''
    #     for bin in wstunnel/*; do
    #       mode=$(stat -c%a $bin)
    #       chmod +w $bin
    #       patchelf --set-interpreter /lib/ld-linux-armhf.so.3 $bin
    #       chmod $mode $bin
    #     done
    #   '';
    #   installPhase = ''
    #     mkdir -p $out/
    #     zip -r -9 $out/${pkgs.stdenv.hostPlatform.config}-wstunnel-${wstunnel-info.rev or "unknown"}.zip wstunnel
    #   '';
    # };

    # cncli = (pkgs.rust-nix.buildPackage {
    #   root = ./cncli;
    #   buildInputs = (with nativePkgs; [ autoconf m4 file ]) ++ (with pkgs; [ libsodium libsodium.dev ]);
    #   # cargoOptions = (opts: opts ++ [ "--verbose" ]);
    #   # cargoBuildOptions = (opts: opts ++ [ "-L ${pkgs.libsodium}/lib" ]);
    #   override = x: x // {
    #     NIX_LDFLAGS_BEFORE_x86_64_unknown_linux_musl = "-lgcc";
    #     OPENSSL_INCLUDE_DIR = "${pkgs.pkgsStatic.openssl.dev}/include";
    #     OPENSSL_LIB_DIR = "${pkgs.pkgsStatic.openssl.out}/lib";
    #     SODIUM_LIB_DIR = "${pkgs.libsodium.out}/lib";
    #     buildInputs = x.buildInputs ++ (with nativePkgs; [ autoconf m4 file ]) ++ (with pkgs.pkgsStatic; [ gmp gmp.dev mpfr mpfr.dev libmpc ]);
    #   };
    # }).overrideAttrs (oldAttrs: oldAttrs // { NIX_DEBUG=7; });

    tarball = nativePkgs.stdenv.mkDerivation {
      name = "${pkgs.stdenv.targetPlatform.config}-tarball";
      buildInputs = with nativePkgs; [ patchelf zip ];

      phases = [ "buildPhase" "installPhase" ];

      buildPhase = ''
        mkdir -p cardano-node
        cp ${cardano-cli}/bin/*cardano-cli* cardano-node/
        cp ${cardano-node.override { enableTSanRTS = false; }}/bin/*cardano-node* cardano-node/
      '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && !pkgs.stdenv.targetPlatform.isMusl) ''
        for bin in cardano-node/*; do
          mode=$(stat -c%a $bin)
          chmod +w $bin
          patchelf --set-interpreter /lib/ld-linux-armhf.so.3 $bin
          chmod $mode $bin
        done
      '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isWindows) ''
        cp ${pkgs.libffi}/bin/*.dll cardano-node/
      '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && !pkgs.stdenv.targetPlatform.isMusl) ''
        cp ${pkgs.libffi}/lib/*.so* cardano-node/
        cp ${pkgs.gmp}/lib/*.so* cardano-node/
        cp ${pkgs.ncurses}/lib/*.so* cardano-node/
        cp ${pkgs.zlib}/lib/*.so* cardano-node/
        echo ${pkgs.stdenv.cc}/lib
        ls cardano-node/
      '';
      installPhase = ''
        mkdir -p $out/
        zip -r -9 $out/${pkgs.stdenv.hostPlatform.config}-cardano-node-${cardano-node-info.rev or "unknown"}.zip cardano-node

        mkdir -p $out/nix-support
        echo "file binary-dist \"$(echo $out/*.zip)\"" \
          > $out/nix-support/hydra-build-products
      '';
    };

}) toBuild
