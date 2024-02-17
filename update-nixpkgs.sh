#!/usr/bin/env bash

nix flake lock  --update-input nixpkgs --commit-lock-file
