# `pyria.nix`, an experiment for secure declarative environments

*in memory of envoidia*

## what is pyria?

pyria is, in a way, a manifestation of my paranoia. in that same way, it is a
dream that there *is* a way for us to stay secure in today's terrifying world,
to mitigate the risk that comes from one half of the tech world evolving faster
than the backbone it leans on. 

pyria is an experiment, too. there's no proof this works in practice any better
than just lobbing a firewall and severe sanitization behind any connection, but
every line of configuration in this flake assures that this isn't some security
theatre either. 

pyria's nixos module currently focuses on kernel-space hardening, and apparmor
compatibility for nix. this is intentional. there are ideas in the basin for
securing the boot process, more userspace hardening, etc, but they are not 
close enough to completion to include in this project as it stands.

pyria's home-manager module is currently a simple subset of the nixos module,
only functionality that's relevant to a user's configuration is included. it
should work on any nix home-manager flake, and i use it on my non-nixos machine
to test that.

despite that, do note that this project is still a work in progress. i run a
lot of the configurations set up on this flake on my own linux install, but i'm
still working out a lot of kinks in the armor of this machine. we've come a
long way with what we have, but there's a long way to go and a lot of code 
that's yet to be written. keep checking for updates, i'm sure more will come
soon.

## what's available now?

### nixos module: `pyria`

this is pyria's base module, this is what you want to use to build secure
systems and what most people will use the most. this serves as page 1 and 2 of
the hardening documentation found below.


# `pyria` hardening documentation

## page 1: hardening the kernel

the most obvious step in hardening a linux distro is to harden the kernel. we
offer configuration as to what flavor (fork/version) and config (sysctls and
kernel parameters) are used. these config options are available at 
`config.pyria.kernel.{flavor,config}`

### `"common"` kernel configuration

this is the secure daily-driver baseline. it incorporates everything that was
previously split across the `"loose"` and `"hardened"` tiers — there is no
longer a softer option. if you need ptrace or user namespaces, apparmor handles
per-application delegation instead of lowering the system-wide floor.

####  kernel parameters

- `init_on_alloc/init_on_free=1` - zero out memory when its allocated or freed,
this mitigates use-after-free bugs wrt leaking old data
- `slab_nomerge` - the kernel normally merges "slab caches" with similar sizes
to save memory, merging creates possible exploitation paths. this disables that
feature.
- `slab_debug=ZP` - enables red zones and poisoning for the kernel slab
allocator, catching heap corruption at the cost of a small performance hit.
- `randomize_kstack_offset=on` - randomizes the kernel stack offset on every
syscall. this makes stack-based kernel exploits much harder to aim.
- `page_alloc.shuffle=1` - randomizes the free page list, making some classes
of heap attacks significantly harder.
- `pti=on` - page table isolation, the meltdown fix. keeps kernel page tables
out of userspace.
- `spectre_v2=on` - spectre variant 2 mitigation.
- `spec_store_bypass_disable=on` - spectre v4 mitigation.
- `mds=full` - mitigates microarchitectural data sampling, preventing a class
of bugs that leak data across cpu boundaries.
- `kvm.nx_huge_pages=force` - forces NX bits on KVM huge pages, mitigating the
iTLB multihit vulnerability.
- `amd_iommu=on`, `iommu.strict=1`, `iommu.passthrough=0` - enables amd iommu
in strict mode, devices can only DMA to memory they're explicitly allowed to
access. prevents a compromised/malicious device from reading arbitrary memory.
- `efi=disable_early_pci_dma` - disables pci dma prior to iommu initialization,
preventing early-boot malicious/compromised devices from reading arbitrary
memory.
- `mem_encrypt=on` - enables memory encryption. for my amd machine, this is SME;
my bios supports TSME so this is redundant but it's nice to explicitly opt-in.
- `random.trust_cpu=off` - we refuse to exclusively trust the cpu for entropy,
opting to include `jitterentropy_rng` as an initrd module to help.
- `random.trust_bootloader=off` - we also refuse to trust the bootloader for
entropy.
- `vsyscall=none` - removes the vulnerable legacy vsyscall mechanism.
- `debugfs=off` - explicitly disables debugfs, which exposes internal kernel
information.
- `module.sig_enforce` - block all unsigned modules.
- `lockdown=confidentiality` - kernel lockdown mode; blocks `/dev/mem`, raw
disk access, hibernation, and other paths that could leak or overwrite kernel
memory. this is the highest lockdown level.
- `oops=panic` - if the kernel hits an oops, panic instead of continuing. a
kernel that has oops'd is likely in a vulnerable state.
- `apparmor=1` - enables the apparmor LSM.

#### sysctl parameters

- `vm.mmap_rnd_bits=32` / `vm.mmap_rnd_compat_bits=16` - maximum ASLR entropy
for memory mappings.
- `vm.mmap_min_addr=65536` - prevents mapping the zero page, eliminating null
pointer dereference exploits.
- `kernel.kptr_restrict=2` - hides kernel pointers from all users incl root.
- `kernel.dmesg_restrict=1` - only root can read `dmesg`.
- `kernel.printk="3 3 3 3"` - limits what kernel messages get printed to the
console.
- `kernel.kexec_load_disabled=1` - disables `kexec`, which would normally allow
runtime kernel-swapping.
- `kernel.core_pattern="|/bin/false"` - core dumps get silently discarded.
- `fs.suid_dumpable=0` - setuid programs dont produce core dumps to begin with.
- `net.core.bpf_jit_harden=2` - hardens the BPF JIT compiler, reducing its
attack surface.
- `kernel.unprivileged_bpf_disabled=1` - only root can load BPF programs.
- `vm.unprivileged_userfaultfd=0` - restricts the `userfaultfd` syscall to
root, mitigating some heap exploit techniques.
- `fs.protected_hardlinks/symlinks=1` - prevents hard/symlink-based TOCTOU
attacks.
- `fs.protected_regular/fifos=2` - extends the above protection to regular/fifo
files, and prevents privilege escalation via O_CREAT.
- `dev.tty.ldisc_autoload=0` - disables automatic TTY line discipline module
loading.
- `kernel.sysrq=4` - only allow `sync` sysrqs.
- `kernel.randomize_va_space=2` - full ASLR.
- `kernel.perf_event_paranoid=3` - `perf` events restricted to root only.
- `kernel.yama.ptrace_scope=1` - a process may only ptrace its own children.
  scope 3 (global disable) was considered but rejected: debuggers and
  proton-battleye have legitimate reasons to ptrace child processes. instead,
  apparmor profiles grant the `ptrace` permission explicitly to the specific
  applications that need it; everything else is blocked at the apparmor layer.
- `kernel.unprivileged_userns_clone=1` with
  `kernel.apparmor_restrict_unprivileged_userns=1` and
  `kernel.apparmor_restrict_unprivileged_unconfined=1` - user namespaces are
  enabled at the kernel level but apparmor gates them per-application. a process
  must have an apparmor profile that explicitly grants userns before creation
  succeeds; unconfined processes are also blocked. this lets containers and
  chromium-sandboxed browsers work without opening userns to everything.

*network-specific sysctl params, these often apply to both ipv4 and ipv6*
- `tcp_rfc1337=1` - protects against TIME-WAIT assassination attacks.
- `tcp_syncookies=1` - prevents SYN floods.
- `tcp_timestamps=0` - disables TCP timestamps, which can aid fingerprinting.
- `accept/secure/send_redirects=0` - block all ICMP redirects, preventing
routing hijack attacks.
- `accept_source_route=0` - disables source routing.
- `rp_filter=2` - verifies that incoming packets could've come from where they
claim.
- `log_martians=1` - log packets with impossible source addresses.
- `net.ipv6.use_tempaddr=2` - uses temporary randomized addresses instead of
mac-derived addresses.
- `net.ipv6.accept_ra=0` - don't accept router advertisements, which can
redirect all traffic.

### `"fortress"` kernel configurations

> note: expect a system slowdown of 50-75% while using this kernel
> configuration. disabling SMT and enabling full slab debug each carry
> 30-50% performance hits individually.

everything in `"common"`, *and*

#### kernel parameters

- `slab_debug=FZP` - upgrades common's `ZP` to `FZP`, adding full consistency
checks on every slab allocation. do not pass go, immediately lose 50-70% of
your system performance.
- `nosmt` - completely disable simultaneous multithreading. do not pass go,
immediately lose 30-50% of your cpu performance.
- `mds=full,nosmt` - mitigates MDS with explicit buffer flushes on every
kernel → user transition; nosmt reduces the performance cost of this.
- `l1tf=full,nosmt` - mitigates L1 terminal faults (Foreshadow), flushing the
L1 data cache on each kernel → user transition; nosmt reduces the cost.

#### sysctl parameters

- `kernel.yama.ptrace_scope=3` - nobody can ptrace *anything*, overriding
  common's apparmor-delegated scope 1. no exceptions.
- `kernel.unprivileged_userns_clone=0` - fully disables user namespace creation,
  overriding common's apparmor-gated approach. no exceptions.

### blacklisted modules

the following modules have been blacklisted; they've fallen out of mainstream
use, have large attack surfaces, and are often ripe with CVEs:
```
  "dccp" "sctp" "rds" "tipc"
  "n-hdlc" "ax25" "netrom" "x25"
  "rose" "decnet" "econet" "af_802154"
  "ipx" "appletalk" "atm" "can"
  "rxrpc" "algif_aead" "rds" "rds_tcp"
  "esp4" "esp6"
```

## page 2: hardening userspace

### subsection a: global permissions via apparmor

one of the biggest barriers to nix adoption within the security space, by my
estimate, has likely been the lack apparmor compatibility with nix. fixing this
is a work-in-progress in the realm of adopting apparmor's implicit path 
priority system to work with non-fhs filesystems and making its dfa segments 
more efficient. our `apparmor.nix` flake provides a mediocre patch while we
work on patches to apparmor and apparmor.d that we'll be working on adding
upstream.

### subsection b: kernel-enforced permission isolation via stronghold \[WIP]

firejail looks like a good isolation application, sure, but it fails at some
critical points; it's a setuid binary, for one, it has a long history of 
relevant CVEs in that regard. it also uses UID 0 as the user id within the
namespace it creates, leaving users open to namespace escape vulnerabilities.

our solution for this is a new application called "stronghold". it's completely
compatible with firejail profiles, enforced at the kernel level, and it pairs 
more than well with apparmor, IMA, and fs-verity.

it's currently in the works, you can check back soon to see progress!

## page 3: hardening the boot process and securing data at rest.

