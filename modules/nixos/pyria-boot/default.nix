{ lanzaboote, ... }:
{
  imports = [
    lanzaboote.nixosModules.lanzaboote
    ./options.nix
    ./secureboot.nix
    ./luks.nix
  ];
}
