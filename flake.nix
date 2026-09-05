{
  description = "pyria.nix, an experiment for secure declarative environments";
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    apparmor-nix = {
      url = "github:lvehrt/apparmor.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { nixpkgs, apparmor-nix, lanzaboote, ... }: {
    nixosModules = {
      pyria = import ./modules/nixos/pyria { inherit inputs nixpkgs apparmor-nix; };
      pyria-boot = import ./modules/nixos/pyria-boot { inherit inputs lanzaboote; };
    };
  };
}
