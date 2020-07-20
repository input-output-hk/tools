#! /usr/bin/env nix-shell
#! nix-shell -p nixops nix jq bash -i bash

top="$(cd `dirname $0`; pwd)"

# export NIX_PATH="$top"
export NIX_PATH="nixpkgs=http://nixos.org/channels/nixos-20.03/nixexprs.tar.xz"
export NIXOPS_STATE="$top/secrets/state.nixops"
export NIXOPS_DEPLOYMENT=hercules-ci-agents

if [ $1 == "deploy" ]; then
  keys="ci.mightybyte.net-1:LXywRTa8NaNw7x32JJOncRMxFk2I36K6Tf6ac8VRnho= hercules-ci.cachix.org-1:ZZeDl9Va+xe9j+KqdzoBZMFJHVQ42Uu/c/1/KMC5Lw0= $(nix show-config --json  | jq -r '.["trusted-public-keys"].value|join(" ")')"
  subs="s3://zeus-ci https://hercules-ci.cachix.org $(nix show-config --json  | jq -r '.["trusted-substituters"].value|join(" ")')"
  cache=("--option" "builders-use-substitutes" "true" "--option" "substituters" "$subs" "--option" "trusted-public-keys" "'$keys'")
else
  cache=()
fi

exec nixops "$@" "${cache[@]}"
