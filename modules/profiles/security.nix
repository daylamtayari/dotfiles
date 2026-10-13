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

let
  # Firefox ESR, wrapped so it cannot borrow the everyday Firefox's session.
  #
  # nixpkgs' Firefox wrapper exports MOZ_LEGACY_PROFILES=1, so ESR resolves the
  # *same* profile root as plain firefox (~/Library/Application Support/Firefox
  # on macOS, ~/.mozilla/firefox on Linux), and MOZ_ALLOW_DOWNGRADE=1, so ESR
  # will silently open a profile last written by the newer release channel
  # instead of warning. On macOS it also exports MOZ_APP_LAUNCHER='firefox' —
  # the '-esr' launcher suffix is Linux-only — which is the same remoting name
  # plain Firefox uses, so launching Firefox ESR.app while Firefox is running
  # is handed off to that process and merely raises one of its windows.
  #
  # --profile pins ESR to its own directory and --no-remote stops the handoff.
  esrProfileDir = "${config.home.homeDirectory}/.local/share/firefox-esr";

  esrLauncher = pkgs.writeShellScript "firefox-esr" ''
    mkdir -p "${esrProfileDir}"
    exec "${
      if pkgs.stdenv.hostPlatform.isDarwin then
        "${pkgs.firefox-esr}/Applications/Firefox ESR.app/Contents/MacOS/firefox"
      else
        "${pkgs.firefox-esr}/bin/firefox-esr"
    }" --no-remote --profile "${esrProfileDir}" "$@"
  '';

  esrInfoPlist = pkgs.writeText "firefox-esr-Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleExecutable</key><string>firefox-esr</string>
      <key>CFBundleIdentifier</key><string>org.nixos.firefox-esr</string>
      <key>CFBundleName</key><string>Firefox ESR</string>
      <key>CFBundleDisplayName</key><string>Firefox ESR</string>
      <key>CFBundleIconFile</key><string>firefox.icns</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>CFBundleShortVersionString</key><string>${pkgs.firefox-esr.version}</string>
      <key>NSHighResolutionCapable</key><true/>
    </dict>
    </plist>
  '';

  # This output deliberately contains *only* the launcher (plus the app bundle /
  # desktop entry that starts it). Installing pkgs.firefox-esr directly is not
  # an option on Linux anyway: it lays its browser down in lib/firefox/** and
  # bin/.firefox-wrapped — named after the *unsuffixed* app, so exactly the
  # paths plain firefox from core-gui.nix claims — and Home Manager's profile
  # buildEnv fails on the collision.
  firefox-esr-isolated =
    pkgs.runCommandLocal "firefox-esr-isolated-${pkgs.firefox-esr.version}"
      { passthru.unwrapped = pkgs.firefox-esr; }
      (
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''
            app="$out/Applications/Firefox ESR.app/Contents"
            mkdir -p "$app/MacOS" "$app/Resources"
            cp ${esrInfoPlist} "$app/Info.plist"
            ln -s "${pkgs.firefox-esr}/Applications/Firefox ESR.app/Contents/Resources/firefox.icns" \
              "$app/Resources/firefox.icns"
            # exec'ing the real bundle's binary keeps the app identity (icon,
            # Dock name) of upstream's Firefox ESR.app; this bundle only injects
            # the flags, so it stays a few KB rather than a 200 MB copy.
            ln -s ${esrLauncher} "$app/MacOS/firefox-esr"
          ''
        else
          ''
            mkdir -p $out/bin $out/share
            ln -s ${esrLauncher} $out/bin/firefox-esr
            # Upstream's desktop entry and icons are already suffixed
            # (firefox-esr.desktop / firefox-esr.png), so they do not collide
            # and can be reused as-is — and its Exec= is a bare `firefox-esr`
            # resolved from PATH, which now finds the launcher above.
            ln -s ${pkgs.firefox-esr}/share/applications $out/share/applications
            ln -s ${pkgs.firefox-esr}/share/icons $out/share/icons
          ''
      );
in

{
  options.my.profiles.security.enable =
    lib.mkEnableOption "cyber-security toolkit";

  config = lib.mkIf config.my.profiles.security.enable {
    home.packages = with pkgs; [

      # Recon / network scanning
      nmap
      masscan
      asnmap
      assetfinder
      gowitness
      nbtscan
      net-snmp # snmpwalk, snmpget, …

      # Web application testing
      # Testing browser, kept separate from the everyday firefox in
      # core-gui.nix: the ESR branch pins a stable extension/API surface for the
      # security add-ons and for proxying through Burp. Unlike plain firefox
      # this one is not Linux-only — nixpkgs builds it for aarch64-darwin too.
      # See the `let` block above for why it is wrapped rather than installed
      # directly.
      firefox-esr-isolated
      ffuf
      feroxbuster
      gobuster
      sqlmap
      wpscan

      # Exploitation / Active Directory
      metasploit
      python3Packages.impacket # secretsdump.py, psexec.py, …
      evil-winrm
      enum4linux
      neo4j # BloodHound's database backend
      exploitdb # searchsploit

      # Password cracking
      hashcat
      thc-hydra # `hydra`

      # Reverse engineering / mobile
    ]
    # Linux-only in nixpkgs — excluded on macOS. ike-scan / veracrypt /
    # bloodhound have Homebrew equivalents (darwin/common.nix); vpnc has none
    # — openconnect (above) ships vpnc-script and covers it.
    #
    # bloodhound-ce is the maintained Community Edition; nixpkgs removed the
    # legacy Electron `bloodhound` app (2025-09). CE is a web server that needs
    # PostgreSQL + Neo4j running — the databases are not managed here.
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      # Web proxy
      # Burp Suite ships one jar for both editions now; the actual edition is
      # decided at runtime by the license. Upstream dropped the `proEdition`
      # boolean for `iconName`, which only picks the icon / desktop entry.
      (burpsuite.override { iconName = "pro"; })
      ike-scan
      veracrypt
      bloodhound-ce
      vpnc
      john
    ];
  };
}
