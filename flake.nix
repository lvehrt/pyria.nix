{
  description = "";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";

    };
    apparmor-nix = {
      url = "github:lvehrt/apparmor.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, apparmor-nix, ... }: {
    nixosModules = {
      pyria = import ./modules/nixos/default.nix { inherit inputs nixpkgs apparmor-nix; };
    };
  };
}