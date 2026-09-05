{ lib, config, pkgs, ... }:
let
  cfg = config.pyria.security.apparmor;
in
{
  security.apparmor.enable = cfg.enable;
  security.apparmor.killUnconfinedConfinables = cfg.strict;
  security.apparmor.packages = lib.optionals cfg.enable [ pkgs.apparmor-d-nix ];
}
