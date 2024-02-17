{ inputs, lib, pkgs, system, ... }:

with lib;

let target_hostname = (builtins.getEnv "TARGET_HOSTNAME");
in
{
  # load module config to top-level configuration

  system.stateVersion = "23.05";
  boot.tmp.useTmpfs = true;
  programs.mosh.enable = true;
  boot.supportedFilesystems = lib.mkForce [ "btrfs" "f2fs" "ext4" "vfat" ];

  time.timeZone = "Europe/Prague";

  fileSystems = {
    "/" = {
      options = [ "noatime" "nodiratime" ];
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  sdImage = {
    swap.size = lib.mkForce 2048;
    extraFirmwareConfig = {
      dtoverlay = "pi3-disable-bt";
    };
  };
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

  boot.kernelParams = lib.mkForce [ "console=tty0" ];

  # not going to cross build so it's enabled in stage2
  services.octoprint = {
    openFirewall = true;
    enable = false;
  };

  services.openssh = {
    enable = lib.mkDefault true;
  };

  users.mutableUsers = false;
  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        ""
      ];
    };
  };

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      mc
      tmux
      htop
      bat
      ncdu
      file
      iperf
      pstree
      sysstat
      usbutils
      powertop
      libraspberrypi
      vim
      ;
  };

  networking = {
    hostName = target_hostname;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # NTP time sync.
  services.timesyncd.enable = true;

  services.avahi = {
    enable = true;
    nssmdns = true;
    ipv4 = true;
    ipv6 = true;
    openFirewall = true;
    allowInterfaces = [ "wlan0" ];
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}

