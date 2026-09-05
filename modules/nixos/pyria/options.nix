{ lib, config, ... }:
{
  options.pyria = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Enable Pyria, an experiment for secure declarative environments";
    };
    # compileFromSource = {
    #   enable = lib.mkOption {
    #     type = lib.types.bool;
    #     default = false;
    #     example = true;
    #     description = "Compile every package and derivation locally";
    #   };
    # };
    kernel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.pyria.enable;
        example = true;
        description = "Enable Kernel-level hardening";
      };
      flavor = lib.mkOption {
        type = lib.types.enum [ "mainline" "hardened" "lts" ];
        default = "hardened";
        description = "Which kernel to use (e.g. mainline for linux, hardened for linux-hardened)";
      };
      config = lib.mkOption {
        type = lib.types.enum [ "hardened" "fortress" ];
        default = "hardened";
        description = "Which set of kernel sysctls and commandline arguments to use";
      };
    };
    security = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.pyria.enable;
        example = true;
        description = "Enable Pyria's security overrides.";
      };
      network = {
        dot = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = config.pyria.security.enable;
            description = "Enable System-wide DNS over TLS";
          };
          servers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "9.9.9.9#dns.quad9.net" "149.112.112.112#dns.quad9.net" ];
            description = "Select DoT servers.";
          };
        };
        tailscale = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Configure network policies to securely enable Tailscale";
          };
        };
      };
      apparmor = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.pyria.security.enable;
          description = "Use an experimental AppArmor + apparmor.d patch built for Nix support (WIP)";
        };
        strict = lib.mkOption {
          type = lib.types.bool;
          default = config.pyria.security.apparmor.enable;
          description = "Use stricter AppArmor settings";
        };
      };
      audit = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.pyria.security.enable;
          description = "Enable auditing.";
        };
        extraRules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Extra audit rules";
        };
      };
      allocator = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.pyria.security.enable;
          description = "Replace your system allocator with hardened_malloc";
        };
      };
    };
  };
}