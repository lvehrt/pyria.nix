{ config, lib, ... }:
let
  cfg = config.pyria.boot;
in
{
  config = lib.mkIf (cfg.enable && cfg.luks.enable) {
    boot.initrd.systemd.enable = true;
    boot.initrd.luks.devices.${cfg.luks.name} = {
      device = cfg.luks.device;
    };
  };
}
