{ config, lib, pkgs, ... }:

let 
kernelParams = pkgs.callPackage ({ ... }: 
  let kernelParams = [
    # memory hardening
    "init_on_alloc=1"
    "init_on_free=1"
    "slab_nomerge"
    "randomize_kstack_offset=on"
    "mem_encrypt=on"
    "efi=disable_early_pci_dma"
    "page_alloc.shuffle=1"
    "kvm.nx_huge_pages=force"
    ## these used to be `hardened`+ only, but are now enabled by default.
    ## they have a minor performance impact, but the benefits far
    ## outweigh the cost.
    "spec_store_bypass_disable=on"


    # kernel hardening
    "lockdown=confidentiality"
    "vsyscall=none"
    "debugfs=off"
    "module.sig_enforce"
    "random.trust_cpu=off"
    "random.trust_bootloader=off"
    "oops=panic"

    # hardware hardening
    "amd_iommu=on"
    "iommu.strict=1"
    "iommu.passthrough=0"
    "pti=on"
    "spectre_v2=on"

    # userspace executable hardening
    "ima_appraise=enforce"
    "ima_appraise_tcb"
    "ima_hash=sha256"
  ];
  unhardenedParams = [] ++ lib.mkIf (config.pyria.kernel.config != "fortress") [
    "mds=full"    
    "slab_debug=ZP"
  ];
  hardenedParams = [] ++ lib.mkIf (config.pyria.kernel.config == "fortress") [
    "slab_debug=FZP"
    "mds=full,nosmt"
    "l1tf=full,nosmt"
    "nosmt"
  ];
  apparmorParams = [] ++ lib.mkIf (config.pyria.security.apparmor.enable) [
    "apparmor=1"
  ];
  in kernelParams ++ unhardenedParams ++ hardenedParams ++ apparmorParams);
sysctl = pkgs.callPackage ({ ... }:
  let commonConfig = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.randomize_va_space" = 2;
    "kernel.kexec_load_disabled" = 1;
    "kernel.core_pattern" = "|/bin/false";
    "kernel.printk" = "3 3 3 3";
    "kernel.sysrq" = 4;
    "kernel.unprivileged_userns_clone" = 0;
    "kernel.io_uring" = 1;
    "kernel.perf_event_paranoid" = 3;
    "kernel.yama.ptrace_scope" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_timestamps" = 0;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.default.rp_filter" = 2;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.default.log_martians" = 1;   
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.default.use_tempaddr" = 2;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.rp_filter" = 2;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 2;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    "fs.protected_regular" = 2;
    "fs.protected_fifos" = 2;
    "fs.suid_dumpable" = 0;
    "vm.unprivileged_userfaultfd" = 0;
    "vm.mmap_rnd_bits" = 32;
    "vm.mmap_rnd_compat_bits" = 16;
    "vm.mmap_min_addr" = 65536;
    "vm.swappiness" = 1;
    "dev.tty.ldisc_autoload" = 0;
  };
  hardenedConfig = {} // lib.mkIf (config.pyria.kernel.config == "fortress") {
    "kernel.yama.ptrace_scope" = 3;
    "kernel.unprivileged_bpf_disabled" = 1;
  };
  apparmorConfig = {} // lib.mkIf (config.pyria.security.apparmor.enable) {
    # userns enabled at kernel level but apparmor gates per-application.
    # unprivileged_userns_clone=1 allows creation,
    # apparmor_restrict_unprivileged_userns=1 requires an apparmor profile
    # to explicitly grant userns before it succeeds.

    "kernel.unprivileged_userns_clone" = 1;
    "kernel.apparmor_restrict_unprivileged_userns" = 1;
    "kernel.apparmor_restrict_unprivileged_unconfined" = 1;
  };
  in commonConfig // hardenedConfig // apparmorConfig);
  
in {
  boot.kernelParams = lib.mkIf config.pyria.kernel.enable kernelParams;
  boot.kernel.sysctl = lib.mkIf config.pyria.kernel.enable sysctl;
  boot.blacklistedKernelModules = lib.mkIf config.pyria.kernel.enable  [
    "dccp" "sctp" "rds" "tipc"
    "n-hdlc" "ax25" "netrom" "x25"
    "rose" "decnet" "econet" "af_802154"
    "ipx" "appletalk" "atm" "can"
    # good lord there are lots of zerodays these days
    "rxrpc" "algif_aead" "rds" "rds_tcp"
    # these are technically for protocol encryption but they're so 
    # vulnerable and neither mullvad nor tailscale use them, and if
    # you're using something that does, you should probably be using
    # something else.
    "esp4" "esp6" 
  ];
  boot.initrd.kernelModules = lib.mkIf config.pyria.kernel.enable [ "jitterentropy_rng" ];
}