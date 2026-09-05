{ lib, config, ... }:
{
  options.pyria.boot = {
    # deliberately NOT defaulted to config.pyria.enable: boot changes can
    # brick a machine, so boot hardening is opt-in even when pyria is on.
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Enable Pyria's boot hardening (secure boot, hybrid LUKS unlock)";
    };
    secureboot = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.pyria.boot.enable;
        example = true;
        description = "Enable UEFI secure boot with your own keys, via lanzaboote";
      };
      pkiBundle = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/sbctl";
        example = "/persist/secureboot";
        description = ''
          Directory holding the sbctl PKI bundle (secure boot keys).
          On impermanence setups, point this at persistent storage.
        '';
      };
      efiSysMountPoint = lib.mkOption {
        type = lib.types.str;
        default = "/boot";
        description = "Mount point of the EFI system partition";
      };
    };
    luks = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Let Pyria manage unlocking of the root LUKS2 device";
      };
      mode = lib.mkOption {
        type = lib.types.enum [ "standard" "hybrid" ];
        default = "standard";
        description = ''
          "standard": plain systemd-initrd LUKS unlock of `device`.
          "hybrid": passphrase + hardware-backed (FIDO2/TPM2) key derivation
          with a detached header, as described in pyria.rs's
          docs/crypto/hybrid-enrollment.md.
        '';
      };
      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/disk/by-label/nixos";
        example = "/dev/disk/by-partlabel/nixos";
        description = "The encrypted device to unlock at boot";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = "nixos";
        description = "Device-mapper name the unlocked device appears as";
      };
    };
  };
}
