{ inputs, apparmor-nix, ... }:
{
  inputs.nixpkgs.overlays = [
    apparmor-nix.overlays.default
  ];
  imports = [
    ./options.nix
    ./kernel/config.nix
    ./kernel/flavor.nix
    ./security/network.nix
    ./security/apparmor.nix
    ./security/allocator.nix
  ];
}