{ lib, config, pkgs, ... }: {
  security.apparmor.enable = config.pyria.security.apparmor.enable;
  security.apparmor.killUnconfinedConfinables = config.pyria.security.apparmor.strict;
  security.apparmor.packages = [] ++ lib.mkIf config.pyria.security.apparmor.enable [ pkgs.apparmor-d-nix ];
}