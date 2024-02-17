{ config, lib, pkgs, ... }:

{
  imports = [
    "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
    ./sd-image.nix
  ];

  # Pi Zero 2 struggles to work without swap
  sdImage.swap.enable = true;
  sdImage.extraFirmwareConfig = {
    # Give up VRAM for more Free System Memory
    # - Disable camera which automatically reserves 128MB VRAM
    start_x = 0;
    # - Reduce allocation of VRAM to 16MB minimum for non-rotated (32MB for rotated)
    gpu_mem = 16;
  };
  # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low on space.
  sdImage.compressImage = false;

  # Enable OpenSSH out of the box.
  services.sshd.enable = true;

  # NTP time sync.
  services.timesyncd.enable = true;

}
