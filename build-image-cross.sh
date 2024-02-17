#!/usr/bin/env bash

source ./lib/prepare.sh

nix build --extra-experimental-features nix-command --extra-experimental-features flakes --impure --max-jobs 1 --update-input nixpkgs --commit-lock-file .#nixosConfigurations.rpiImage
