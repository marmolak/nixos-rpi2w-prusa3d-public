{
  description = "NixOS Raspberry Pi configuration flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }@inputs: {
    nixosConfigurations = {
      rpi =
        let
          system = "aarch64-linux";
          config = config;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          lib = pkgs.lib;
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            {
              nixpkgs.buildPlatform.system = "x86_64-linux";
              nixpkgs.hostPlatform.system = "aarch64-linux";
            }
            (import ./raspberry-pi-zero-2.nix { inherit config lib pkgs; })
            (import ./stage1/configuration.nix { inherit inputs lib pkgs system; })
          ];
        };
      rpiNative =
        let
          system = "aarch64-linux";
          config = config;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          lib = pkgs.lib;
        in
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            (import ./raspberry-pi-zero-2.nix { inherit config lib pkgs; })
            ./stage2/extra-modules/generic-extlinux-compatible
            (import ./stage2/configuration.nix { inherit inputs lib pkgs system; })
          ];
        };
      rpiImage = self.nixosConfigurations.rpi.config.system.build.sdImage;
    };
  };
}
