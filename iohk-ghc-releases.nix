{ pkgs, stdenv, fetchgit }:
{ bootGhc, version, rev, sha256 }:
{
    tarball = stdenv.mkDerivation rec {

        name = "ghc-${version}";
        inherit version;

        outputs = [ "out" ];

        src = fetchgit {
            url = "https://gitlab.haskell.org/iohk/ghc.git";
            inherit rev sha256;
            fetchSubmodules = true;
        };

        buildInputs = [ bootGhc ] ++ (with pkgs; [
            python3
            haskellPackages.alex haskellPackages.happy_1_19_5
            cabal-install
            gmp gmp.dev
            autoreconfHook
            pkgconfig
            xlibs.lndir
            ]);

        preConfigure = ''
            python ./boot
        '';

        # this is required to work around some weird expectaion of the existance
        # of this filder from the sdist make target.
        preBuild = ''
            mkdir ghc-tarballs
        '';
        makeFlags = [ "sdist" "-s" ];
        installPhase = ''
            mkdir -p $out/nix-support

            cp ./sdistprep/*.tar.xz $out/

            for artifact in $out/*.tar.xz; do
                echo "file binary-dist \"''${artifact}\"" \
                >> $out/nix-support/hydra-build-products
            done
        '';

    };
}
