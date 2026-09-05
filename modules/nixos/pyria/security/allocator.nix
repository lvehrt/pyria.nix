{ lib, config, ... }:
{
  environment.memoryAllocator.provider =
    lib.mkIf config.pyria.security.allocator.enable (lib.mkDefault "graphene-hardened");
}
