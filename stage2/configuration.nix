{ inputs, lib, pkgs, system, ... }:

with lib;

let
  checkNotEmptyAssert = val:
    assert isString val;
    assert asserts.assertMsg (val != "") "Variable is empty!";
    val;

  target_hostname = checkNotEmptyAssert (builtins.getEnv "TARGET_HOSTNAME");
  wifi-ssid = checkNotEmptyAssert (builtins.getEnv "WIFI_SSID");
  wifi-psk = checkNotEmptyAssert (builtins.getEnv "WIFI_PSK");
  wifi-country = checkNotEmptyAssert (builtins.getEnv "WIFI_COUNTRY_S");


in
{
  # load module config to top-level configuration

  system.stateVersion = "unstable";
  programs.mosh.enable = true;

  boot = {
    tmp.useTmpfs = true;

    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = [ "bcm2835_dma" "i2c_bcm2835" ];
    supportedFilesystems = lib.mkForce [ "btrfs" "f2fs" "ext4" "vfat" ];

    loader.timeout = 1;
    loader.generic-extlinux-compatible.configurationLimit = 1;
  };

  hardware = {
    deviceTree = {
      enable = true;
    };

    enableRedistributableFirmware = mkForce false;
    firmware = [ pkgs.raspberrypiWirelessFirmware ];
  };

  documentation.enable = false;
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  programs.command-not-found.enable = false;

  time.timeZone = "Europe/Prague";

  services.journald.extraConfig = "Storage=volatile";
  powerManagement.cpuFreqGovernor = "performance";

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

  nixpkgs.overlays = [
    (self: super: {
      ubootRaspberryPi3_64bit = super.ubootRaspberryPi3_64bit.overrideAttrs (oldAttrs: {
        extraConfig = ''
          CONFIG_BOOTDELAY=-2
          CONFIG_SILENT_CONSOLE=y
          CONFIG_SYS_DEVICE_NULLDEV=y
          CONFIG_SILENT_CONSOLE_UPDATE_ON_SET=y
          CONFIG_SILENT_U_BOOT_ONLY=y
          CONFIG_AUTOBOOT_KEYED=y
          CONFIG_AUTOBOOT_PROMPT="NO UART\0"
          CONFIG_AUTOBOOT_DELAY_STR="iddqd\0"
          CONFIG_AUTOBOOT_STOP_STR="idkfa\0"
        '';
      });
      octoprint = super.octoprint.override {
        packageOverrides = pyself: pysuper: {
          octoprint-iponconnect = pyself.buildPythonPackage rec {
            pname = "ipOnConnect";
            version = "0.2.4";
            src = self.fetchFromGitHub {
              owner = "jneilliii";
              repo = "OctoPrint-ipOnConnect";
              rev = "${version}";
              sha256 = "sha256-tAEnGC11rHWa2hoW+ZLhjqY21WPOgdvuXejGJ4uqkuE=";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
          };
          octoprint-hadiscovery = pyself.buildPythonPackage rec {
            pname = "HomeAssistant Discovery";
            version = "3.7.0";
            src = self.fetchFromGitHub {
              owner = "cmroche";
              repo = "OctoPrint-HomeAssistant";
              rev = "${version}";
              sha256 = "sha256-R6ayI8KHpBSR2Cnp6B2mKdJGHaxTENkOKvbvILLte2E=";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
          };
        };
      };
    })
  ];

  services.octoprint = {
    openFirewall = true;
    enable = true;
    plugins = plugins: with plugins; [
      bedlevelvisualizer
      stlviewer
      mqtt
      themeify
      octoprint-iponconnect
      octoprint-hadiscovery
    ];

    # FIX: allow restore from backup.
    # Octoprint want's to rename octoprint directory to octoprint.bck in /var/lib but without luck.
    stateDir = "/var/lib/octoprint-root/octoprint";

    extraConfig = {
      server = {
        commands = {
          serverRestartCommand = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/systemctl restart octoprint";
          systemRestartCommand = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/reboot";
          systemShutdownCommand = "/run/wrappers/bin/sudo ${pkgs.systemd}/bin/poweroff";
        };
      };
    };
  };

  # Part of FIX for octoprint (more in services.octoprint.
  systemd.tmpfiles.rules = [
    "d /var/lib/octoprint-root/ 0770 octoprint octoprint -"
    "d /var/lib/octoprint-root/octoprint 0770 octoprint octoprint -"
  ];

  services.openssh = {
    enable = lib.mkDefault true;
  };

  security.sudo = {
    enable = true;
    extraRules = [{
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl restart octoprint";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/reboot";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/poweroff";
          options = [ "NOPASSWD" ];
        }
      ];
      groups = [ "octoprint" ];
    }];
  };

  users.mutableUsers = false;
  users.users = {
    root = {
      openssh.authorizedKeys.keys = [
        ""
      ];
    };

    octoprint = {
      extraGroups = [ "video" ];
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
      neofetch
      ;
  };

  networking = {
    hostName = target_hostname;

    interfaces."wlan0".useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
      extraConfig = "${wifi-country}";
      networks = {
        "${wifi-ssid}" = {
          psk = "${wifi-psk}";
          hidden = true;
        };
      };
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # NTP time sync.
  services.timesyncd.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
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

  services.udev.extraRules = ''
    KERNEL=="vchiq", GROUP="video", MODE="0660", TAG+="systemd", ENV{SYSTEMD_ALIAS}="/dev/vchiq"
  '';
}
