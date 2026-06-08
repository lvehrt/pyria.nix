{ lib, config, ... }:
{
  options.pyria = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Enable Pyria, an experiment for secure declarative environments";
    };
    compileFromSource = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Compile every package and derivation locally";
      };
    };
    programs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = config.pyria.enable;
        example = true;
        description = "Enable Kernel-level hardening";
      };
      hardened-malloc = lib.mkOption {
        type = lib.types.bool;
        default = config.pyria.programs.enable;
        description = "Substitute your system allocator with hardened_malloc where possible.";
      };
      firefox = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          example = true;
          description = "Enable re-wrapping of certain firefox packages in order to add secure configurations as default.";
        };
        override = {
          prefs = lib.mkOption {
            type = lib.types.submodule;
            default = {};
            example = {
              "privacy.sanitize.timeSpan" = 3000;
            };
            description = "Preferences to globally change on certain firefox packages";
          };
          policies = lib.mkOption {
            type = lib.types.submodule;
            default = {};
            example = {
              DontCheckDefaultBrowser = false;
            };
            description = "Enterprise policies to globally change on certain firefox packages";
          };
        };
      };
    };
  };
}