let niv-sources = import ../nix/sources.nix {}; in
with import niv-sources.nixpkgs {};
stdenv.mkDerivation rec {
    name = "nixops-shell";

    buildInputs = [
        nixops
        jq
        bash
        cacert
    ];

    shellHook = ''
        export NIX_PATH="nixpkgs=${niv-sources.nixpkgs}"
        export NIXOPS_STATE="./secrets/state.nixops"
        export NIXOPS_DEPLOYMENT=loony-tools-builder

        function nixops () {
            if [ $1 == "deploy" ]; then
                keys="$(nix show-config --json  | jq -r '.["trusted-public-keys"].value|join(" ")')"
                subs="$(nix show-config --json  | jq -r '.["trusted-substituters"].value|join(" ")')"
                cache=("--option" "builders-use-substitutes" "true" "--option" "substituters" "$subs" "--option" "trusted-public-keys" "$keys")
            else
                cache=()
            fi

            ${nixops}/bin/nixops "$@" "''${cache[@]}"
        }
    '';
}