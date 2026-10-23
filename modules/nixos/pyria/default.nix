{ inputs, apparmor-nix, ... }:
{
  nixpkgs.overlays = [
    apparmor-nix.overlays.default
  ];
  imports = [
    ./options.nix
    ./kernel/config.nix
    ./kernel/flavor.nix
    ./kernel/module-certs.nix
    ./security/network.nix
    ./security/apparmor.nix
    ./security/allocator.nix
  ];
}