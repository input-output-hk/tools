let
  # Fetch the latest haskell.nix and import its default.nix
  haskellNix = import (builtins.fetchTarball https://github.com/input-output-hk/haskell.nix/archive/angerman/arm-plus.tar.gz) {};
  # haskell.nix provides access to the nixpkgs pins which are used by our CI, hence
  # you will be more likely to get cache hits when using these.
  # But you can also just use your own, e.g. '<nixpkgs>'
  nixpkgsSrc = haskellNix.sources.nixpkgs-2003;
  # haskell.nix provides some arguments to be passed to nixpkgs, including some patches
  # and also the haskell.nix functionality itself as an overlay.
  nixpkgsArgs = haskellNix.nixpkgsArgs;
in
{ nativePkgs ? import nixpkgsSrc (nixpkgsArgs // { overlays = nixpkgsArgs.overlays ++ [(final: prev: { libsodium = final.callPackage ./libsodium.nix {}; })]; })
, haskellCompiler ? "ghc865"
, wstunnel-json
, wstunnel-info ? __fromJSON (__readFile wstunnel-json)
, wstunnel-src ? nativePkgs.fetchgit (removeAttrs wstunnel-info [ "date" ])
}:
let toBuild = with nativePkgs.pkgsCross; {
  # x86-gnu32 = gnu32;
  x86-gnu64 = nativePkgs; #gnu64; # should be == nativePkgs
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

    __wstunnel = (pkgs.haskell-nix.cabalProject {
      compiler-nix-name = haskellCompiler;
      src = wstunnel-src;
      modules = [];
    });

    inherit (__wstunnel.wstunnel.components.exes) wstunnel;

    wstunnel-tarball = nativePkgs.stdenv.mkDerivation {
      name = "${pkgs.stdenv.targetPlatform.config}-tarball";
      buildInputs = with nativePkgs; [ patchelf zip ];

      phases = [ "buildPhase" "installPhase" ];
      buildPhase = ''
        mkdir -p wstunnel
        cp ${wstunnel}/bin/*wstunnel* wstunnel/
      '' + pkgs.lib.optionalString (pkgs.stdenv.targetPlatform.isLinux && !pkgs.stdenv.targetPlatform.isMusl) ''
        for bin in wstunnel/*; do
          mode=$(stat -c%a $bin)
          chmod +w $bin
          patchelf --set-interpreter /lib/ld-linux-armhf.so.3 $bin
          chmod $mode $bin
        done
      '';
      installPhase = ''
        mkdir -p $out/
        zip -r -9 $out/${pkgs.stdenv.hostPlatform.config}-wstunnel-${wstunnel-info.rev or "unknown"}.zip wstunnel
      '';
    };

}) toBuild
