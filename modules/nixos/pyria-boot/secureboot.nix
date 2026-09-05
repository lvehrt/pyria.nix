{ config, lib, pkgs, ... }:
let
  cfg = config.pyria.boot;
in
{
  config = lib.mkIf (cfg.enable && cfg.secureboot.enable) {
    # lanzaboote replaces systemd-boot as the thing that populates the ESP
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = cfg.secureboot.pkiBundle;
    };
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = cfg.secureboot.efiSysMountPoint;
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
