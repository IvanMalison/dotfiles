# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ../configuration.nix
    ../dfinity.nix
    ];

  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.luks.devices."cryptroot".device = "/dev/nvme0n1p5";
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  # install nvidia drivers in addition to intel one
  hardware.opengl.extraPackages = [ pkgs.linuxPackages.nvidia_x11.out ];
  hardware.opengl.extraPackages32 = [ pkgs.linuxPackages.nvidia_x11.lib32 ];
  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };

  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/356173ab-d076-43e0-aeb6-6a6829c4402b";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B270-C7E6";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/f719b44e-295a-4909-9a60-84f87acb7f77"; }
    ];

  networking.hostName = "ryzen-shine";

  nix.maxJobs = lib.mkDefault 16;
  # High-DPI console
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";

  system.stateVersion = "20.03"; # Did you read the comment?
}