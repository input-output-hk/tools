#!/usr/bin/env bash

top="$(cd `dirname $0`; pwd)"

# export NIX_PATH="$top"
export NIX_PATH="nixpkgs=http://nixos.org/channels/nixos-19.03/nixexprs.tar.xz"
export NIXOPS_STATE="$top/secrets/state.nixops"
export NIXOPS_DEPLOYMENT=hercules-ci-agents

exec nixops "$@"
