# nixos/work/default.nix — work NixOS machine (system side).
#
# configuration.nix and hardware-configuration.nix are copied verbatim from the
# machine's /etc/nixos — they hold the bootloader, disks, hostname, desktop and
# system.stateVersion chosen at install time. Shared system config lives in
# ../common.nix; the Home Manager side is hosts/work.nix (shared with the Mac).
{ config, pkgs, user, ... }:

{
  imports = [
    ./configuration.nix # imports ./hardware-configuration.nix itself
    ../common.nix
  ];

  # Sway desktop. The compositor is system-side (PAM for swaylock, polkit, xdg
  # portals, a session entry for the display manager); its config, rofi,
  # Waybar and kanshi come from the HM profile (modules/profiles/sway.nix).
  # Enabled here rather than in hosts/work.nix, which the Mac shares.
  programs.sway = {
    enable = true;
    # SwayFX — drop-in Sway fork that adds rounded corners (picom's job on i3).
    package = pkgs.swayfx;
  };
  home-manager.users.${user} = {
    my.profiles.sway.enable = true;

    # Route SSH through 1Password's agent (enable it in 1Password → Settings →
    # Developer → "Use the SSH agent"). Set here rather than in hosts/work.nix
    # because the socket path is Linux-specific — the Mac's lives under
    # ~/Library/Group Containers. The rest of the SSH config (including the
    # local.conf include) is shared, in modules/ssh.nix.
    programs.ssh.matchBlocks."*".identityAgent = "~/.1password/agent.sock";

    # Start 1Password minimized to the tray with the Sway session, so the SSH
    # agent socket above (and browser/CLI integration) is up without opening
    # the app first. Tied to graphical-session.target so it gets Sway's
    # WAYLAND_DISPLAY and stops with the session.
    systemd.user.services._1password = {
      Unit = {
        Description = "1Password";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${config.programs._1password-gui.package}/bin/1password --silent";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Mic-mute LED (F4) follows the default source's mute state — the same
    # thing the XF86AudioMicMute binding toggles (modules/profiles/sway.nix).
    # The kernel's audio-micmute trigger is detached below (udev rule) because
    # it tracks the HDA codec's headset-jack capture switch, which PipeWire
    # leaves off, so the LED was always lit. brightnessctl writes the LED
    # through logind, so no root or udev permissions are needed.
    systemd.user.services.micmute-led = {
      Unit = {
        Description = "Sync the mic-mute LED with the default source";
        After = [ "pipewire-pulse.service" ];
        Wants = [ "pipewire-pulse.service" ];
      };
      Service = {
        ExecStart = "${pkgs.writeShellApplication {
          name = "micmute-led";
          runtimeInputs = [ pkgs.pulseaudio pkgs.brightnessctl ];
          text = ''
            last=""
            sync() {
              if [ "$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)" = "Mute: yes" ]; then
                state=1
              else
                state=0
              fi
              if [ "$state" != "$last" ]; then
                brightnessctl -q -d platform::micmute s "$state" && last=$state
              fi
            }
            sync
            # Source events cover mute toggles; server events cover a change
            # of default source (e.g. plugging in a USB mic).
            pactl subscribe | while read -r line; do
              case "$line" in
                *" on source "* | *" on server "*) sync ;;
              esac
            done
          '';
        }}/bin/micmute-led";
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };

  # Detach the micmute LED from the kernel's audio-micmute trigger so only the
  # micmute-led user service above drives it.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::micmute", ATTR{trigger}="none"
  '';

  # Boot straight to a login prompt that launches Sway (the install chose "No
  # desktop", so there is no other display manager to conflict with).
  # --remember pre-fills the last username.
  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
  };

  # Audio — a "No desktop" install leaves it out, and Sway does not provide
  # it. PipeWire with the PulseAudio shim, so pavucontrol (core-gui.nix) works.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    # Make a newly connected output (e.g. Bluetooth headphones) the default
    # sink/source. pipewire-pulse's port of PulseAudio's
    # module-switch-on-connect; HDMI outputs are ignored by default.
    extraConfig.pipewire-pulse."90-switch-on-connect" = {
      "pulse.cmd" = [
        { cmd = "load-module"; args = "module-switch-on-connect"; flags = [ ]; }
      ];
    };
  };

  # Docker daemon — the dev profile installs only the docker clients on Linux
  # and expects the system to provide the daemon.
  virtualisation.docker.enable = true;
  users.users.${user}.extraGroups = [ "docker" ];

  # Tailscale — work tailnet. Authenticate once with `tailscale up`; tailscaled
  # persists the login and the up/down state, so it reconnects on its own at
  # boot. extraSetFlags are applied by `tailscale set` on every tailscaled
  # start: --accept-routes takes subnet routes advertised by other nodes, and
  # the operator flag lets the user drive the CLI without sudo. openFirewall opens
  # the WireGuard UDP port so peers connect directly instead of via DERP;
  # useRoutingFeatures = "client" loosens rp_filter so exit nodes and subnet
  # routes advertised by other nodes work.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraSetFlags = [ "--accept-routes" "--operator=${user}" ];
  };

  hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
    };
  services.blueman.enable = true;

  # Sleep. This ThinkPad's firmware only exposes s2idle (/sys/power/mem_sleep
  # has no "deep" — S3 is gone on these AMD models), and s2idle drains the
  # battery overnight. So the "deep" sleep is suspend-then-hibernate: s2idle
  # first, then after HibernateDelaySec write RAM to the encrypted swap
  # (29.8G ≥ 27G RAM) and power off. The initrd already unlocks that swap's
  # LUKS volume (configuration.nix), so resume just needs pointing at it.
  boot.resumeDevice = "/dev/mapper/luks-70b1ff41-bea7-46f0-ba12-8ac594b95efe";
  # HibernateOnACPower = false: while plugged in, stay suspended and don't
  # start the HibernateDelaySec countdown until AC is disconnected — so
  # unplugging a closed, sleeping laptop still ends in hibernation. systemd
  # wakes every SuspendEstimationSec to check power state (default 1h), so
  # an unplug is noticed at most 15 min late. It also hibernates early if
  # the battery hits ~5% while suspended.
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "15min";
    HibernateOnACPower = false;
    SuspendEstimationSec = "15min";
  };

  # Lid close → suspend-then-hibernate everywhere; the AC/battery split is
  # handled by HibernateOnACPower above rather than by a separate plain
  # "suspend" for ExternalPower, which would never hibernate if unplugged
  # while asleep. swayidle's before-sleep hook locks the screen first.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
    # Docked = an external monitor (or dock) is connected; logind checks this
    # before ExternalPower, so it must be set too. To keep working on the
    # external monitor with the lid shut, set this to "ignore" — Sway's lid
    # bindswitch (modules/profiles/sway.nix) then blanks the internal panel.
    HandleLidSwitchDocked = "suspend-then-hibernate";
  };

  # Fingerprint reader (Goodix 27c6:6594, match-on-chip — stock libfprint
  # goodixmoc driver). Enabling fprintd turns on pam_fprintd for every PAM
  # service by default (sudo, swaylock, polkit/1Password, greetd), falling back
  # to the password. Enroll once with `fprintd-enroll`.
  services.fprintd.enable = true;

  # swaylock only starts PAM once Enter is pressed, and pam_fprintd runs first
  # by default — so a typed password sat waiting for a finger. Check the
  # password first instead: type it + Enter to unlock, or press Enter on an
  # empty prompt and then touch the reader.
  security.pam.services.swaylock.rules.auth.fprintd.order =
    config.security.pam.services.swaylock.rules.auth.unix.order + 10;

  # Secret Service keyring — 1Password (and browsers, nm-applet, …) store
  # credentials here; without one Sway has no org.freedesktop.secrets provider.
  # greetd's PAM stack unlocks it with the login password, so login must stay
  # password-only: a fingerprint login can't derive the keyring key and would
  # leave it locked (1Password then prompts for it on every start). This also
  # makes the first auth after boot always a password; fingerprint is only
  # accepted afterwards (swaylock, sudo, polkit).
  #
  # greetd's PAM file is just `substack login`, so fprintd has to be disabled
  # on `login` itself — fprintAuth = false on greetd alone has no effect.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.fprintAuth = false;
  programs.seahorse.enable = true; # GUI for browsing/resetting the keyring

  # 1Password — the system modules (not a plain package) are needed for the
  # polkit unlock prompt, browser integration and `op` CLI integration.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ user ];
  };
}
