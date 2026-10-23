{ config, options, pkgs, lib, ... }:
let
  kernelPackages = config.boot.kernelPackages;
  target = kernelPackages.kernel.target;
  finalKernel = kernelPackages.rebuildImage {
    inherit target;
    inherit (config.system) modulesTree;
  };
  kernelPath = "${finalKernel}/${target}";
  enable = config.pyria.kernel.enable && kernelPackages ? rebuildImage;
in {
  # since 7.3, nixpkgs signs every module with its own kmodigest cert but
  # only embeds those certs into the image via rebuildImage, which nothing
  # calls by default. without them the builtin keyring is empty, so
  # module.sig_enforce and lockdown reject every module (including the
  # initrd's storage drivers) and the system can't find its root disk.
  # mirrors nixos/tests/kernel-module-verification.nix in nixpkgs.
  config = lib.mkIf enable {
    system.systemBuilderCommands = lib.mkAfter ''
      ln -sf -- ${kernelPath} $out/kernel
    '';

    # bootloaders (systemd-boot, lanzaboote) install the kernel named in
    # boot.json, not $out/kernel, and boot.json is written after
    # systemBuilderCommands, so point it at the rebuilt image too.
    boot.bootspec.writer = ''
      ${options.boot.bootspec.writer.default}
      ${pkgs.buildPackages.jq}/bin/jq --sort-keys --arg kernel ${kernelPath} \
        '."org.nixos.bootspec.v1".kernel = $kernel' \
        $out/${config.boot.bootspec.filename} > "$TMPDIR/bootspec.json"
      mv -- "$TMPDIR/bootspec.json" $out/${config.boot.bootspec.filename}
    '';
  };
}
