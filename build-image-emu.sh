#!/usr/bin/env bash

source ./lib/prepare.sh

nix build --impure --extra-experimental-features nix-command --extra-experimental-features flakes --update-input nixpkgs --commit-lock-file --max-jobs 1 .#nixosConfigurations.rpiNative.config.system.build.sdImage
