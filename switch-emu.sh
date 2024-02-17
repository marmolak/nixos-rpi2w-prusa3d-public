#!/usr/bin/env bash

source ./lib/prepare.sh

nixos-rebuild boot --impure --update-input nixpkgs --upgrade-all --target-host root@"${TARGET_HOSTNAME}.local" --flake .#rpiNative --commit-lock-file
