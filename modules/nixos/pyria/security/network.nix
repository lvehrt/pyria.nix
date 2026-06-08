{ config, lib, ... }:
{
  services.resolved = lib.mkIf (config.pyria.security.network.dot.enable) {
    settings.Resolve = {
      DNSOverTLS = "yes";
      DNSSEC = "true";
      Domains = [ "~." ];
      DNS = config.pyria.security.network.dot.servers;
      FallbackDNS = [ "9.9.9.9#dns.quad9.net" ];
    };
  };
  networking.firewall.allowedUDPPorts = lib.mkIf (config.pyria.security.network.tailscale.enable) [ config.services.tailscale.port ];
  systemd.network.networks."50-tailscale" = lib.mkIf (config.pyria.security.network.tailscale.enable) {
    matchConfig.Name = "tailscale0";
    networkConfig = {
      DNS = [ "100.100.100.100" ];
      Domains = "~ts.net";
      LLMNR = false;
      MulticastDNS = false;
      MTUBytes = "1280";
    };
  };
}