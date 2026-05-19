# modules/profiles/security.nix — opt-in cyber-security toolkit.
#
# Always imported so `my.profiles.security.enable` exists on every host;
# contributes packages only where a host enables it (currently `cyber`).
#
# Built from the `cyber` VM's package list (~/QubesIncoming/cyber/cyber-pkgs)
# diffed against the `dev` VM — i.e. the tools `cyber` adds on top of
# core + core-gui + dev. Dependency/library noise and non-security packages
# from that diff were dropped.
{ config, lib, pkgs, ... }:

{
  options.my.profiles.security.enable =
    lib.mkEnableOption "cyber-security toolkit";

  config = lib.mkIf config.my.profiles.security.enable {
    home.packages = with pkgs; [
      # Web proxy
      (burpsuite.override { proEdition = true; }) # Burp Suite Professional

      # Recon / network scanning
      nmap
      masscan
      massdns
      asnmap
      assetfinder
      gowitness
      nbtscan
      ike-scan
      net-snmp # snmpwalk, snmpget, …

      # Web application testing
      ffuf
      feroxbuster
      gobuster
      sqlmap
      wpscan

      # Exploitation / Active Directory
      metasploit
      python3Packages.impacket # secretsdump.py, psexec.py, …
      netexec # CrackMapExec successor
      evil-winrm
      enum4linux
      bloodhound
      neo4j # BloodHound's database backend
      exploitdb # searchsploit

      # Password cracking
      hashcat
      john
      thc-hydra # `hydra`

      # Reverse engineering / mobile
      ghidra
      jadx
      apktool

      # Traffic analysis
      wireshark # Qt GUI, bundles tshark
      termshark

      # Wordlists
      seclists

      # Secrets / dependency scanning
      trufflehog
      snyk
      dependency-check

      # Misc
      veracrypt
      minio-client # `mc` — object-storage / S3 client
      openconnect
      vpnc
      firefox-esr # dedicated browser for proxying through Burp
    ];
  };
}
