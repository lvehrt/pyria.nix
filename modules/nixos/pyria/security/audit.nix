{ config, lib, ... }:
{
  security.audit.enable = config.pyria.security.audit.enable;
  security.audit.rules = config.pyria.security.audit.extraRules ++ lib.mkIf config.pyria.security.audit.enable [
    "-a exit,always -F arch=b64 -S execve"
    "-w /etc/passwd -p wa"
    "-w /etc/shadow -p wa"
    "-w /sbin/insmod -p w"
    "-w /sbin/modprobe -p w"
    "-w /sbin/rmmod -p w"
    "-w /etc/sudoers -p wa"
    "-w /root/.ssh -p wa"
    "-a always,exit -F arch=b64 -S setuid -S setgid"
    "-a always,exit -F arch=b64 -S capset"
    "-a always,exit -F arch=b64 -S socket"
  ];
}