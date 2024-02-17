# nixos-rpi2w-prusa3d


How to use this repository
==========================

**NOTE**
Install Nix first, if you don't have NixOS:

[Nix install instructions](https://nixos.org/manual/nix/stable/installation/installation#multi-user)

**NOTE**
Cross build really rebuilds all packages from source, which is slow and binary cache
is not used. It takes very much of resources (cpu power, time,...).

On non-NixOS linux, you should edit `/etc/nixos/nix.conf` and add something like (tested on Fedora 39):

```
extra-platforms = aarch64-linux
extra-sandbox-paths = /usr/bin/qemu-aarch64-static
```

For Fedora 39, you need to install:

qemu-system-aarch64
qemu-user
qemu-user-binfmt
qemu-user-static-aarch64

Then, you can use `build-image-emu.sh`.


**NOTE** `build-image-emu.sh` is preferred way how to build image.
With cross compiling in place, different hashes are generated so
you need to repopulate (reupload) system in stage2 step.
Which wears SD card, because almost whole system is rewritten.
Also, reupload break hack for rpi zero 2w in `sd-image.nix` so manual
adjustmen is needed because you will end up with unbootable system
(missing dtb file).

Pros and cons to have NixOS on rpi
----------------------------------
Pros:
 - easy to make image with customised configuration
 - easy updates

Cons:
 - unable to modify config.txt directly - you need to use another device tree magic (still in progress for me).


`build-image-cross.sh` - two stages compilation
-----------------------------------------------

1) stage1 - build image with cross compiler
2) stage2 - use `nix-rebuild` to populate remote machine with additional configuration.

`build-image-emu.sh` - one stage build
--------------------------------------

In case that you have enabled:

`boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` (aarch64-emu in folloving text)

then you can just build whole image at once.

`switch-cross.sh` - populate/upgrade remote machine
---------------------------------------------

Just use `nixos-rebuild` to deploy new configuration.

`switch-emu.sh` - populate/upgrade remote machine
---------------------------------------------

Uses `nixos-rebuild`.

In case you have aarch64-emu enabled, then build host emulated and only results
are placed to target machine

