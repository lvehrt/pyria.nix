{ config, ... }: {
  security.ima.enable = config.pyria.security.enable;
}