{ pkgs ? import <nixpkgs> {} }:
let iohk-ghc-releases = pkgs.callPackage ./iohk-ghc-releases.nix {};
in {
    ghc-865-iohk1 = iohk-ghc-releases (rec {
        bootGhc = pkgs.haskell.compiler.ghc865;
        version = "8.6.5-iohk1-${rev}";
        rev = "6a77ed7ed3d38c6aeda376143e1aea265a24412a";
        sha256 = "00v0i0g0k4xlkgvdb7h70jf2acg21bf00rghmnz1zl2z8wy2id2p";
    });
}