{ lib, config, ... }: {
  environment.memoryAllocator.provider = lib.mkIf config.pyria.security.allocator lib.mkDefault "graphene-hardened";
} 