#!/usr/bin/env bash

source ./lib/prepare.sh

nixos-rebuild boot --update-input nixpkgs --upgrade-all --impure --build-host root@"${TARGET_HOSTNAME}.local" --target-host root@"${TARGET_HOSTNAME}.local" --flake .#rpiNative --fast --commit-lock-file
