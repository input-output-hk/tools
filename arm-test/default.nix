let
  sources = import ./nix/sources.nix {};
  # Fetch the latest haskell.nix and import its default.nix
  haskellNix = import sources."haskell.nix" {};
  # haskell.nix provides access to the nixpkgs pins which are used by our CI, hence
  # you will be more likely to get cache hits when using these.
  # But you can also just use your own, e.g. '<nixpkgs>'
  nixpkgsSrc = haskellNix.sources.nixpkgs-2211;
  #nixpkgsSrc = sources.nixpkgs-m1; #haskellNix.sources.nixpkgs-2009; #sources.nixpkgs; #
  # haskell.nix provides some arguments to be passed to nixpkgs, including some patches
  # and also the haskell.nix functionality itself as an overlay.
  nixpkgsArgs = haskellNix.nixpkgsArgs;
in
{ system ? __currentSystem
, nativePkgs ? import nixpkgsSrc (nixpkgsArgs // { overlays =
    # [ (import ./rust.nix)] ++
    nixpkgsArgs.overlays ++
    [
      (final: prev: { libsodium-vrf = final.callPackage ./libsodium.nix {}; })
      (final: prev: { llvmPackages_13 = prev.llvmPackages_13 // {
          compiler-rt-libc = prev.llvmPackages_13.compiler-rt-libc.overrideAttrs (old: {
            cmakeFlags = with old.stdenv.hostPlatform; old.cmakeFlags ++ [ "-DCOMPILER_RT_BUILD_MEMPROF=OFF" ];
          });}; })
    ]
    ;
    inherit system;
    })
, haskellCompiler ? "ghc8107"
, cardano-node-info ? sources.cardano-node
, cardano-node-src ? cardano-node-info
, cardano-wallet-src ? sources.cardano-wallet
, ogmios-src ? sources.ogmios
, bech32-src ? sources.bech32
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
  # x86-musl32 = musl32;``
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

  inherit ghcjs aarch64-android;
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

  __ogmios = (pkgs.haskell-nix.cabalProject {
    cabalProjectLocal  =  pkgs.lib.optionalString (pkgs.stdenv.targetPlatform != pkgs.stdenv.buildPlatform) ''
    package unix-bytestring
      ghc-options: -Wno-error
    package plutus-core
      ghc-options: -Wno-error
    '';
    compiler-nix-name = haskellCompiler;
    src = nativePkgs.stdenv.mkDerivation {
      name = "cleaned-source";
      phases = [ "unpackPhase" "installPhase" ];
      src = ogmios-src;
      nativeBuildInputs = [ nativePkgs.rsync ];
      installPhase = ''
        mkdir -p $out/
        rsync -a $src/server/ $out/ --exclude "package.yaml"
      '';
    };
    modules = [
      {
#        packages.unix-bytestring.patches = [ ./cardano-node-patches/unix-bytestring-0.3.7.3.patch ];
#        packages.terminal-size.patches = [ ./cardano-node-patches/terminal-size-0.3.2.1.patch ];
        packages.plutus-core.patches = [ ./cardano-node-patches/plutus-core.patch ];
      }
    ];
  });
  inherit (__ogmios.ogmios.components.exes) ogmios;

  ogmios-tarball = nativePkgs.stdenv.mkDerivation {
    name = "${pkgs.stdenv.targetPlatform.config}-tarball";
    buildInputs = with nativePkgs; [ patchelf zip ];

    phases = [ "buildPhase" "installPhase" ];

    buildPhase = ''
      mkdir -p ogmios
      cp ${ogmios}/bin/*ogmios* ogmios/
    '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && pkgs.stdenv.targetPlatform.isGnu) ''
      for bin in ogmios/*; do
        mode=$(stat -c%a $bin)
        chmod +w $bin
        patchelf --set-interpreter /lib/ld-linux-armhf.so.3 $bin
        chmod $mode $bin
      done
    '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isWindows) ''
      cp ${pkgs.libffi}/bin/*.dll ogmios/
      ${nativePkgs.tree}/bin/tree ${pkgs.gmp}
      cp ${pkgs.gmp}/bin/*.dll* ogmios/
      ${nativePkgs.tree}/bin/tree ${pkgs.zlib}
      cp ${pkgs.zlib}/bin/*.dll* ogmios/
    '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && pkgs.stdenv.targetPlatform.isGnu) ''
      cp ${pkgs.libffi}/lib/*.so* ogmios/
      cp ${pkgs.gmp}/lib/*.so* ogmios/
      cp ${pkgs.ncurses}/lib/*.so* ogmios/
      cp ${pkgs.zlib}/lib/*.so* ogmios/
      echo ${pkgs.stdenv.cc}/lib
      ls ogmios/
    '';
    installPhase = ''
      mkdir -p $out/
      zip -r -9 $out/${pkgs.stdenv.hostPlatform.config}-ogmios-${ogmios-src.rev or "unknown"}.zip ogmios

      mkdir -p $out/nix-support
      echo "file binary-dist \"$(echo $out/*.zip)\"" \
        > $out/nix-support/hydra-build-products
    '';
  };


  cardano-node = nativePkgs.lib.mapAttrs (_: cardano-node-info:
    let cardano-node-src = cardano-node-info; in rec {
    __cardano-node = (pkgs.haskell-nix.cabalProject {
        inputMap = { "https://input-output-hk.github.io/cardano-haskell-packages" = sources.cardano-haskell-packages; };
        cabalProjectLocal  =  pkgs.lib.optionalString (pkgs.stdenv.targetPlatform != pkgs.stdenv.buildPlatform) ''
          -- When cross compiling we don't have a `ghc` package
          package plutus-tx-plugin
            flags: +use-ghc-stub
          '';
        compiler-nix-name = haskellCompiler;
        # pkgs.haskell-nix.haskellLib.cleanGit { name = "cardano-node"; src = ... } <- this doesn't work with fetchgit results
        src = cardano-node-src;
        # ghc = pkgs.buildPackages.pkgs.haskell-nix.compiler.${haskellCompiler};
        modules = [
          # Allow reinstallation of Win32
          # { nonReinstallablePkgs =
          #  [ "rts" "ghc-heap" "ghc-prim" "integer-gmp" "integer-simple" "base"
          #    "deepseq" "array" "ghc-boot-th" "pretty" "template-haskell"
          #    # ghcjs custom packages
          #    "ghcjs-prim" "ghcjs-th"
          #    "ghc-boot"
          #    "ghc" "array" "binary" "bytestring" "containers"
          #    "filepath" "ghc-boot" "ghc-compact" "ghc-prim"
          #    # "ghci" "haskeline"
          #    "hpc"
          #    "mtl" "parsec" "text" "transformers"
          #    "xhtml"
          #    # "stm" "terminfo"
          #  ];
          # }
          # haddocks are useless (lol);
          # and broken for cross compilers!
          { doHaddock = false; }
          { compiler.nix-name = haskellCompiler; }
          { packages.cardano-config.flags.systemd = false;
            packages.cardano-node.flags.systemd = false; }
          { # packages.terminal-size.patches = [ ./cardano-node-patches/terminal-size-0.3.2.1.patch ];
            # packages.unix-bytestring.patches = [ ./cardano-node-patches/unix-bytestring-0.3.7.3.patch ];
            packages.plutus-core.patches = [ ./cardano-node-patches/plutus-core.patch ];

            # We need the following patch to work around this grat failure :(
            # src/Cardano/Config/Git/Rev.hs:33:35: error:
            #     • Exception when trying to run compile-time code:
            #         git: readCreateProcessWithExitCode: posix_spawn_file_actions_adddup2(child_end): invalid argument (Invalid argument)
            #       Code: gitRevFromGit
            #     • In the untyped splice: $(gitRevFromGit)
            #    |
            # 33 |         fromGit = T.strip (T.pack $(gitRevFromGit))
            #    |
            packages.cardano-config.patches = [ ./cardano-node-patches/cardano-config-no-git-rev.patch ];
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
          ({ pkgs, lib, ... }: lib.mkIf (pkgs.stdenv.hostPlatform.isAndroid) {
            packages.iohk-monitoring.patches = [ ./cardano-node-patches/iohk-monitoring-framework-625.diff ];
            # android default inlining threshold seems to be too high for closure_sizeW to be inlined properly.
            packages.cardano-prelude.ghcOptions = [ "-optc=-mllvm" "-optc-inlinehint-threshold=500" ];
            packages.cardano-node.ghcOptions = [ "-pie" ];
          })
          ({ pkgs, lib, ... }: lib.mkIf (!pkgs.stdenv.hostPlatform.isGhcjs) {
            packages = {
              # See https://github.com/input-output-hk/iohk-nix/pull/488
              cardano-crypto-praos.components.library.pkgconfig = lib.mkForce [ [ pkgs.libsodium-vrf pkgs.secp256k1 ] ];
              cardano-crypto-class.components.library.pkgconfig = lib.mkForce [ [ pkgs.libsodium-vrf pkgs.secp256k1 ] ];
            };
          })
          ({ pkgs, lib, ... }: lib.mkIf (pkgs.stdenv.hostPlatform.isGhcjs) {
            packages =
              let libsodium-vrf = pkgs.libsodium-vrf.overrideAttrs (attrs: {
                    nativeBuildInputs = attrs.nativeBuildInputs or [ ] ++ (with pkgs.buildPackages.buildPackages; [ emscripten python2 ]);
                    prePatch = ''
                      export HOME=$(mktemp -d)
                      export PYTHON=${pkgs.buildPackages.buildPackages.python2}/bin/python
                    '' + attrs.prePatch or "";
                    configurePhase = ''
                      emconfigure ./configure --prefix=$out --enable-minimal --disable-shared --without-pthreads --disable-ssp --disable-asm --disable-pie CFLAGS=-Os
                    '';
                    CC = "emcc";
                  });
                  emzlib = pkgs.zlib.overrideAttrs (attrs: {
                    # makeFlags in nixpks zlib derivation depends on stdenv.cc.targetPrefix, which we don't have :(
                    prePatch = ''
                      export HOME=$(mktemp -d)
                      export PYTHON=${pkgs.buildPackages.buildPackages.python2}/bin/python
                    '' + attrs.prePatch or "";
                    makeFlags = "PREFIX=js-unknown-ghcjs-";
                    # We need the same patching as macOS
                    postPatch = ''
                      substituteInPlace configure \
                        --replace '/usr/bin/libtool' 'emar' \
                        --replace 'AR="libtool"' 'AR="emar"' \
                        --replace 'ARFLAGS="-o"' 'ARFLAGS="-r"'
                    '';
                    configurePhase = ''
                      emconfigure ./configure --prefix=$out --static
                    '';

                    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ (with pkgs.buildPackages.buildPackages; [ emscripten python2 ]);

                    CC = "emcc";
                    AR = "emar";

                    # prevent it from passing `-lc`, which emcc doesn't like.
                    LDSHAREDLIBC = "";
                  });
              in {
                cardano-crypto-praos.components.library.pkgconfig = lib.mkForce [ [ libsodium-vrf pkgs.secp256k1 ] ];
                cardano-crypto-class.components.library.pkgconfig = lib.mkForce [ [ libsodium-vrf pkgs.secp256k1 ] ];
                digest.components.library.libs = lib.mkForce [ emzlib.static emzlib ];
              };
          })
          # {
          #   packages.cardano-node-capi.components.library = {
          #   };
          # }
        ];
      });
      __bech32 = (pkgs.haskell-nix.cabalProject {
        compiler-nix-name = haskellCompiler;
        src = bech32-src;
        modules = [];
      });

      inherit (__bech32.bech32.components.exes) bech32;

      __cardano-wallet = (pkgs.haskell-nix.cabalProject {
        cabalProjectLocal  =  pkgs.lib.optionalString (pkgs.stdenv.targetPlatform != pkgs.stdenv.buildPlatform) ''
          -- When cross compiling we don't have a `ghc` package
          package plutus-tx-plugin
            flags: +use-ghc-stub
          '';
        compiler-nix-name = haskellCompiler;
        src = cardano-wallet-src;
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
          { doHaddock = false; }
          { compiler.nix-name = haskellCompiler; }
          { packages.cardano-config.flags.systemd = false;
            packages.cardano-node.flags.systemd = false; }
          { # packages.terminal-size.patches = [ ./cardano-node-patches/terminal-size-0.3.2.1.patch ];
            # packages.unix-bytestring.patches = [ ./cardano-node-patches/unix-bytestring-0.3.7.3.patch ];
            packages.plutus-core.patches = [ ./cardano-node-patches/plutus-core.patch ];
            packages.scrypt.patches = [ ./cardano-wallet-patches/scrypt-0.5.0.patch ];
          }
          {
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

      inherit (__cardano-wallet.cardano-wallet.components.exes) cardano-wallet;
      inherit (__cardano-node.cardano-node.components.exes) cardano-node;
      inherit (__cardano-node.cardano-cli.components.exes)  cardano-cli;
      inherit (__cardano-node.cardano-submit-api.components.exes) cardano-submit-api;

      cardano-node-capi = __cardano-node.cardano-node-capi.components.library.override {
              smallAddressSpace = true; enableShared = false;
              ghcOptions = [ "-shared" "-v" "-optl-Wl,--version-script=${nativePkgs.writeText "libcardano-node-capi.version" ''
              CN_CAPI_1.0 {
                global:
                  hs_init;
                  setLineBuffering;
                  runNode;
                local: *;
              };
              ''}" "-lHSrts_thr" ];
              # NIX_LD_FLAGS="";
              postInstall = ''
                ${nativePkgs.tree}/bin/tree $out
                mkdir -p $out/_pkg
                # copy over includes, we might want those, but maybe not.
                # cp -r $out/lib/*/*/include $out/_pkg/
                # find the libHS...ghc-X.Y.Z.a static library; this is the
                # rolled up one with all dependencies included.
                ${nativePkgs.tree}/bin/tree
                find ./dist -name "libHS*-ghc*.a" -exec cp {} $out/_pkg \;

                cp a.out $out/cardano-node-capi.so
                ${nativePkgs.patchelf}/bin/patchelf --set-soname "cardano-node-capi.so" $out/cardano-node-capi.so
                for x in $(${nativePkgs.patchelf}/bin/patchelf --print-needed $out/cardano-node-capi.so |grep -v "so$"|xargs); do
                  ${nativePkgs.patchelf}/bin/patchelf --replace-needed $x ''${x%%.so.*}.so $out/cardano-node-capi.so;
                done
                # find ${pkgs.libffi.overrideAttrs (old: { dontDisableStatic = true; })}/lib -name "*.a" -exec cp {} $out/_pkg \;
                # find ${pkgs.gmp6.override { withStatic = true; }}/lib -name "*.a" -exec cp {} $out/_pkg \;
                # find ${pkgs.libiconv}/lib -name "*.a" -exec cp {} $out/_pkg \;
                # find ${pkgs.libffi}/lib -name "*.a" -exec cp {} $out/_pkg \;

                # ${nativePkgs.tree}/bin/tree $out/_pkg
                # (cd $out/_pkg; ${nativePkgs.zip}/bin/zip -r -9 $out/pkg.zip *)
                # rm -fR $out/_pkg

                mkdir -p $out/nix-support
                echo "file binary-dist \"$(echo $out/*.zip)\"" \
                    > $out/nix-support/hydra-build-products
              '';
      };

      tarball = nativePkgs.stdenv.mkDerivation {
        name = "${pkgs.stdenv.targetPlatform.config}-tarball";
        buildInputs = with nativePkgs; [ patchelf zip ];

        phases = [ "buildPhase" "installPhase" ];

        buildPhase = ''
          mkdir -p cardano-node
          cp ${cardano-cli}/bin/*cardano-cli* cardano-node/
          cp ${cardano-node.override { enableTSanRTS = false; }}/bin/*cardano-node* cardano-node/
          cp ${cardano-submit-api}/bin/*cardano-submit* cardano-node/
          cp ${bech32}/bin/bech* cardano-node/
        '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && pkgs.stdenv.targetPlatform.isGnu) ''
          for bin in cardano-node/*; do
            mode=$(stat -c%a $bin)
            chmod +w $bin
            patchelf --set-interpreter /lib/ld-linux-armhf.so.3 $bin
            chmod $mode $bin
          done
        '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isWindows) ''
          ${nativePkgs.tree}/bin/tree ${pkgs.libffi}
          cp ${pkgs.libffi}/bin/*.dll cardano-node/
          ${nativePkgs.tree}/bin/tree ${pkgs.gmp}
          cp ${pkgs.gmp}/bin/*.dll* cardano-node/
          ${nativePkgs.tree}/bin/tree ${pkgs.zlib}
          cp ${pkgs.zlib}/bin/*.dll* cardano-node/
        '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && pkgs.stdenv.targetPlatform.isGnu) ''
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

      # Synology package

      # This is the synology package structure:
      # spk
      # ├ ─ ─  INFO                          -- Properties File
      # ├ ─ ─  package.tgz                   -- compress package contents
      # ├ ─ ─  scripts                       -- lifecycle scripts
      # │    ├ ─ ─  preinst                  -- It can be used to check conditions before installation but not to make side effects onto the system. Package installation will be aborted for non-zero returned value.
      # │    ├ ─ ─  postinst                 -- It can be used to prepare environment for package after installed. Package status will become corrupted for non-zero returned value.
      # │    ├ ─ ─  preuninst                -- It can be used to check conditions before uninstallation but not to make side effects onto the system. Package uninstallation will be aborted for non-zero returned value.
      # │    ├ ─ ─  postuninst               -- It can be used to cleanup environment for package after uninstalled.
      # │    ├ ─ ─  preupgrade               -- It can be used to check conditions before upgrade but not to make side effects onto the system. Package upgrade will be aborted for non-zero returned value.
      # │    ├ ─ ─  postupgrade              -- It can be used to prepare environment for package after upgraded. Package status will become corrupted for non-zero returned value.
      # │    ├ ─ ─  prereplace               -- (optional) It can be used to do data migration when install_replace_packages is defined in INFO for package replacement. Package replacement will be aborted for non-zero returned value.
      # │    ├ ─ ─  postreplace              -- (optional) It can be used to do data migration when install_replace_packages is defined in INFO for package replacement. Package replacement will be aborted for non-zero returned value.
      # │    └ ─ ─  start-stop-status        -- It can be used to control package lifecycle.
      # ├ ─ ─  conf                          -- additional configurations
      # │    ├ ─ ─  privilege                -- Define file privilege and execution privilege to secure the package.
      # │    └ ─ ─  resource                 -- (optional) Define system resources that can be used in the lifecycle of package.
      # ├ ─ ─  LICENSE                       -- (optional)
      # ├ ─ ─  PACKAGE_ICON.PNG              -- 64 x 64 png image for Package Center
      # └ ─ ─  PACKAGE_ICON_256.PNG          -- 256 x 256 png image to show in Package Center
      #
      mkSynologySpk = {
        name,
        version,
        run,
        pkg
      }: rec {
        info = nativePkgs.writeTextFile {
          name = "INFO";
          text = ''
            package="${name}"
            version="${version}"
            os_min_ver="7.0-40000"
            description="The cardano full node"
            arch="${pkgs.stdenv.hostPlatform.linuxArch}"
            maintainer="zw3rk"
          '';
        };
        license = nativePkgs.writeTextFile {
          name = "LICENSE";
          text = ''
          ${name} synology package (alpha)

          THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
          '';
        };
        icon64 = ./synology/PACKAGE_ICON.png;
        icon256 = ./synology/PACKAGE_ICON_256.png;

        scripts =
          # default file as per Synology documentation, this file does nothing.
          let defaultFile = name: nativePkgs.writeTextFile {
            inherit name;
            executable = true;
            text = ''
              #!/bin/sh

              exit 0
            '';
          }; in {
            preinst = defaultFile "preinst";
            postinst = defaultFile "postinst";
            preuninst = defaultFile "preuinst";
            postuninst = defaultFile "postuninst";
            preupgrade = defaultFile "preupgrade";
            postupgrade = defaultFile "postupgrade";
            start-stop-status = nativePkgs.writeTextFile {
              name = "start-stop-status";
              executable = true;
              text = ''
                #!/bin/sh

                case "$1" in
                    # this requires precheckstartstop in INFO to be yes.
                    prestart)
                        ;;
                    start)
                      synosystemctl start pkg-${name}.service
                        ;;
                    prestop)
                        ;;
                    stop)
                      synosystemctl stop pkg-${name}.service
                        ;;
                    status)
                        ;;
                esac

                exit 0
              '';
            };
          };

          conf = {
            systemd = {
              service = nativePkgs.writeTextFile {
                name = "pkg-${name}.service";
                text = ''
                  [Unit]
                  Description=${name}
                  After=network-online.target
                  Wants=network-online.target

                  [Service]
                  Type=simple
                  ExecStart=/var/packages/${name}/target/bin/run.sh
                  KillMode=process
                  StandardOutput=journal
                  StandardError=journal
                  SyslogIdentifier=${name}
                  Restart=on-failure
                  RestartSec=15s
                '';
              };
            };

            privilege = nativePkgs.writeTextFile {
              name = "privilege";
              text = builtins.toJSON {
                defaults = {
                  run-as = "package";
                };
              };
            };
            resource = nativePkgs.writeTextFile {
              name = "resource";
              text = builtins.toJSON {
                # systemd-user-unit = {};
                # data-share = {
                #   shared = [{
                #     name = "cardano-node";
                #     permission.rw = [ "cardano-node" ];
                #   }];
                # };
              };
            };
          };

        launcher = nativePkgs.writeTextFile {
          name = "run.sh"; executable = true;
          text = run;
        };

        package = nativePkgs.stdenv.mkDerivation {
          name = "${pkgs.stdenv.targetPlatform.config}-package.tgz";
          buildInputs = with nativePkgs; [ gnutar gzip ];

          phases = [ "buildPhase" "installPhase" ];

          buildPhase = ''
            mkdir -p {bin,etc}
            cp ${pkg}/bin/*                                bin
            cp ${launcher}                                 bin/run.sh
            cp ${./synology}/*.json                        etc
            cp ${./synology}/*.yaml                        etc
            tar -czf package.tgz *
          '';

          installPhase = ''
            mkdir -p $out/
            cp package.tgz $out/
          '';
        };

        spk = nativePkgs.stdenv.mkDerivation {
          name = "${pkgs.stdenv.targetPlatform.config}-${name}.spk";
          buildInputs = with nativePkgs; [ gnutar gzip ];

          phases = [ "buildPhase" "installPhase" ];

          buildPhase = ''
            mkdir -p pkg/{scripts,conf/systemd}
            cp ${info}                       pkg/INFO
            cp ${icon64}                     pkg/PACKAGE_ICON.PNG
            cp ${icon256}                    pkg/PACKAGE_ICON_256.PNG
            cp ${license}                    pkg/LICENSE
            cp ${scripts.preinst}            pkg/scripts/preinst
            cp ${scripts.postinst}           pkg/scripts/postinst
            cp ${scripts.preuninst}          pkg/scripts/preuninst
            cp ${scripts.postuninst}         pkg/scripts/postuninst
            cp ${scripts.preupgrade}         pkg/scripts/preupgrade
            cp ${scripts.postupgrade}        pkg/scripts/postupgrade
            cp ${scripts.start-stop-status}  pkg/scripts/start-stop-status
            cp ${conf.systemd.service}       pkg/conf/systemd/pkg-${name}.service
            cp ${conf.privilege}             pkg/conf/privilege
            cp ${package}/package.tgz        pkg/
            # contrary to other documentaiton online, an spk is just a tarball.
            # gziped or xz'd will throw the synology off, and prevent installation.
            (cd pkg && tar -cf ${name}.spk *)
          '';
          installPhase = ''
            mkdir -p $out/
            mv pkg/${name}.spk $out/

            mkdir -p $out/nix-support
            echo "file binary-dist \"$(echo $out/*.spk)\"" \
              > $out/nix-support/hydra-build-products
          '';
        };
      };
      cardano-node-spk = (mkSynologySpk {
        name = "cardano-node";
        version = cardano-node-info.rev or "unknown";
        pkg = cardano-node;
        run = ''
          #!/bin/sh

          /var/packages/cardano-node/target/bin/cardano-node run \
            --topology /var/packages/cardano-node/target/etc/mainnet-topology.json \
            --config /var/packages/cardano-node/target/etc/mainnet-config.json \
            --port 3001 \
            --host-addr 0.0.0.0 \
            --database-path /var/packages/cardano-node/var/db \
            --socket-path /var/packages/cardano-node/tmp/node.socket
          '';
      }).spk;

      cardano-submit-api-spk = (mkSynologySpk {
        name = "cardano-submit-api";
        version = cardano-node-info.rev or "unknown";
        pkg = cardano-submit-api;
        run = ''
          #!/bin/sh

          /var/packages/cardano-submit-api/target/bin/cardano-submit-api \
            --socket-path /var/packages/cardano-node/tmp/node.socket \
            --config /var/packages/cardano-submit-api/target/etc/tx-submit-mainnet-config.yaml \
            --port 8090 \
            --listen-address 0.0.0.0 \
            --mainnet
          '';
      }).spk;

            # cp ${cardano-cli}/bin/*cardano-cli*            bin
            # cp ${cardano-node}/bin/*cardano-node*          bin
            # cp ${cardano-submit-api}/bin/*cardano-submit*  bin


    }) { "mainnet" = sources.cardano-node-mainnet;
         # "vasil" = sources.cardano-node-vasil;
       };

}) toBuild
