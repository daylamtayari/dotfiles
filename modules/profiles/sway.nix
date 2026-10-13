# modules/profiles/sway.nix — opt-in Sway desktop (Linux / Wayland): rofi
# launcher, Waybar status bar, swayidle + swaylock, wdisplays + kanshi for
# monitor layout.
#
# Converted from the Qubes-era i3 / polybar / rofi configs. Keybindings follow
# config/aerospace/aerospace.toml where the two disagreed (vim hjkl focus/move,
# the 1–15 workspace keys, mod+ctrl+N "bring workspace here"), but the modifier
# stays Super as on i3 rather than AeroSpace's alt.
#
# X11-only pieces were replaced: feh → `output * bg`, xss-lock + betterlockscreen
# → swayidle + swaylock, polybar → Waybar, arandr → wdisplays + kanshi, the yad
# popups → Waybar's calendar tooltip and a rofi power menu. Qubes-only pieces
# (per-qube window colors, qubes-i3-xdg-autostart, qubes-menu, the qube
# window rules) were dropped. picom's rounded corners come from SwayFX instead
# (`corner_radius` below; the swayfx package is set in nixos/work/default.nix).
#
# Home Manager side only. Sway itself must come from the system —
# `programs.sway.enable` on NixOS (PAM for swaylock, polkit, xdg portals), with
# `programs.sway.package = pkgs.swayfx` for rounded corners — so
# `package = null` here. See nixos/work/default.nix.
{ config, lib, pkgs, ... }:

let
  # Super, as on i3. (AeroSpace on the Mac uses alt; kept off alt here so
  # Alt+key shortcuts stay with applications.)
  mod = "Mod4";

  lock = "${pkgs.swaylock}/bin/swaylock -f";
  pactlBin = "${pkgs.pulseaudio}/bin/pactl";
  brightnessctlBin = "${pkgs.brightnessctl}/bin/brightnessctl";

  # Sway port of config/aerospace/bring-workspace.sh (itself a port of the i3
  # switch-workspace.py): pull workspace N onto the output that was focused
  # when the key was pressed. swaymsg comes from the system sway on PATH.
  bringWorkspace = pkgs.writeShellApplication {
    name = "sway-bring-workspace";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      ws="$1"
      # Capture the focused output BEFORE switching — focus jumps to whichever
      # output currently holds the workspace.
      output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
      swaymsg "workspace number $ws; move workspace to output \"$output\"; workspace number $ws"
    '';
  };

  # Replaces polybar's yad popup-powermenu.sh (which still called bspwm's
  # `bspc quit` and had a "Rebooot" typo that made Reboot a no-op).
  powerMenu = pkgs.writeShellApplication {
    name = "sway-power-menu";
    runtimeInputs = [ pkgs.rofi ];
    text = ''
      choice=$(printf 'Lock\nSuspend\nShutdown\nReboot\nLogout\n' | rofi -dmenu -i -p "Power")
      case "$choice" in
        Lock) ${lock} ;;
        Suspend) systemctl suspend ;;
        Shutdown) systemctl poweroff ;;
        Reboot) systemctl reboot ;;
        Logout) swaymsg exit ;;
      esac
    '';
  };

  # Workspace keys shared with AeroSpace: 1–9, 0 → 10, then - = [ ] \ → 11–15.
  workspaceBindings = lib.listToAttrs (lib.concatLists (lib.imap1
    (i: key:
      let ws = toString i; in [
        (lib.nameValuePair "${mod}+${key}" "workspace number ${ws}")
        (lib.nameValuePair "${mod}+Shift+${key}" "move container to workspace number ${ws}")
        (lib.nameValuePair "${mod}+Control+${key}" "exec ${bringWorkspace}/bin/sway-bring-workspace ${ws}")
      ])
    [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "0" "minus" "equal" "bracketleft" "bracketright" "backslash" ]));

  # Window colors from the i3 config's `dom0` palette (the one for windows not
  # owned by a qube). childBorder = background, i3's default when unset.
  palette = border: background: text: indicator: {
    inherit border background text indicator;
    childBorder = background;
  };
in
{
  options.my.profiles.sway.enable =
    lib.mkEnableOption "Sway + rofi + Waybar desktop";

  config = lib.mkIf config.my.profiles.sway.enable {
    wayland.windowManager.sway = {
      enable = true;
      package = null; # provided by NixOS programs.sway (swayfx)
      checkConfig = false; # needs a sway binary in the build, which package = null drops
      # Run XDG autostart entries (the job qubes-i3-xdg-autostart did on Qubes).
      systemd.xdgAutostart = true;

      config = {
        modifier = mod;
        floating.modifier = mod;
        terminal = "kitty";
        menu = "rofi -show drun";
        bars = [ ]; # Waybar runs as a systemd user service instead of swaybar

        fonts = {
          names = [ "FiraCode Nerd Font" ];
          size = 0.0; # as in the i3 config — keeps tabbed/stacked titles minimal
        };

        gaps = {
          inner = 8;
          outer = 0;
        };
        window = {
          border = 4;
          titlebar = false;
        };
        floating = {
          border = 4;
          titlebar = false;
        };

        colors = {
          background = "#c4c4c4";
          focused = palette "#f7f7f7" "#f5f5f5" "#000000" "#0a0a0a";
          focusedInactive = palette "#f7f7f7" "#dcdcdc" "#191919" "#232323";
          unfocused = palette "#f7f7f7" "#c4c4c4" "#323232" "#3b3b3b";
          urgent = palette "#bd2727" "#e79e27" "#333333" "#27bdbd";
        };

        # feh replacement. Missing file → sway shows a config error bar; drop
        # a wallpaper at this path (or change it).
        output."*".bg = "~/Pictures/wallpaper.png fill";

        keybindings = workspaceBindings // {
          # Launch
          "${mod}+Return" = "exec kitty";
          "${mod}+d" = "exec rofi -show drun";

          # Window management
          "${mod}+Shift+q" = "kill";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+space" = "focus mode_toggle";
          "${mod}+a" = "focus parent";

          # Focus / move — vim hjkl like AeroSpace (i3 had jkl;).
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";

          # Move the whole workspace to another monitor — AeroSpace's
          # alt-shift-left/right, plus up/down from the i3 config.
          "${mod}+Shift+Left" = "move workspace to output left";
          "${mod}+Shift+Right" = "move workspace to output right";
          "${mod}+Shift+Up" = "move workspace to output up";
          "${mod}+Shift+Down" = "move workspace to output down";

          # Layout. w / e match AeroSpace (accordion ≈ tabbed, tiles ≈ split).
          # split h moved from mod+h (now focus left) to mod+b, Sway's default.
          "${mod}+b" = "split h";
          "${mod}+v" = "split v";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";

          # Session
          "${mod}+Shift+c" = "reload";
          "${mod}+Shift+e" =
            "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'";
          "${mod}+Control+l" = "exec ${lock}";
          "${mod}+r" = "mode resize";

          # Media / brightness keys
          "XF86AudioRaiseVolume" = "exec ${pactlBin} set-sink-volume @DEFAULT_SINK@ +10%";
          "XF86AudioLowerVolume" = "exec ${pactlBin} set-sink-volume @DEFAULT_SINK@ -10%";
          "XF86AudioMute" = "exec ${pactlBin} set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioMicMute" = "exec ${pactlBin} set-source-mute @DEFAULT_SOURCE@ toggle";
          "XF86MonBrightnessUp" = "exec ${brightnessctlBin} s 10+%";
          "XF86MonBrightnessDown" = "exec ${brightnessctlBin} s 10-%";
        };

        # hjkl + arrows, 50px steps — AeroSpace's resize mode.
        modes.resize = {
          "h" = "resize shrink width 50px";
          "j" = "resize grow height 50px";
          "k" = "resize shrink height 50px";
          "l" = "resize grow width 50px";
          "Left" = "resize shrink width 50px";
          "Down" = "resize grow height 50px";
          "Up" = "resize shrink height 50px";
          "Right" = "resize grow width 50px";
          "Return" = "mode default";
          "Escape" = "mode default";
          "${mod}+r" = "mode default";
        };
      };

      extraConfig = ''
        default_orientation vertical

        # SwayFX-only — replaces picom's rounded corners. Plain sway would
        # reject this line.
        corner_radius 8
      '';
    };

    # xss-lock + betterlockscreen replacement. X's default screensaver fired
    # xss-lock after 10 minutes idle; betterlockscreen's `--off 600` blanked the
    # display 10 minutes after that.
    programs.swaylock = {
      enable = true;
      settings = {
        image = "${config.home.homeDirectory}/Pictures/wallpaper.png";
        scaling = "fill";
        color = "282A2E"; # fallback when the wallpaper is missing
      };
    };
    services.swayidle = {
      enable = true;
      timeouts = [
        { timeout = 600; command = lock; }
        {
          timeout = 1200;
          command = "swaymsg 'output * power off'";
          resumeCommand = "swaymsg 'output * power on'";
        }
      ];
      events.before-sleep = lock;
    };

    programs.rofi = {
      enable = true;
      theme = "gruvbox-dark"; # bundled with rofi
      settings = {
        modes = "drun,window,run";
        timeout = {
          action = "kb-cancel";
          delay = 0;
        };
        filebrowser = {
          directories-first = true;
          sorting-method = "name";
        };
      };
    };

    # polybar replacement — same modules and palette (style.css). Dropped:
    # qubes-menu and the running-qube counter (Qubes-only).
    programs.waybar = {
      enable = true;
      systemd.enable = true; # started with Sway's graphical-session.target
      style = ../../config/waybar/style.css;
      settings.main = {
        layer = "top";
        position = "top";
        height = 32;
        margin = "4 4 0 4"; # polybar's transparent 4pt border

        modules-left = [ "sway/workspaces" "sway/mode" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "memory" "cpu" "battery" "tray" "custom/power" ];

        "sway/workspaces" = {
          all-outputs = false; # polybar pin-workspaces = true
          disable-scroll = false;
        };

        # popup-calendar + hyphen + time. The yad click-popup calendar is
        # replaced by Waybar's built-in calendar tooltip.
        clock = {
          interval = 1;
          format = "{:%A, %B %d} <span color='#707880'>—</span> {:%H:%M}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        pulseaudio = {
          format = "<span color='#F0C674'>{icon}</span> {volume}%";
          format-muted = "<span color='#F0C674'>󰝟</span> muted";
          format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
          on-click = "${pactlBin} set-sink-mute @DEFAULT_SINK@ toggle";
          on-click-right = "pavucontrol";
        };

        memory = {
          interval = 5;
          format = "<span color='#F0C674'></span> {percentage}%";
        };

        # polybar's custom `load` script — 1-minute load average.
        cpu = {
          interval = 5;
          format = "<span color='#F0C674'></span> {load}";
        };

        # Battery auto-detected (polybar hardcoded BAT1).
        battery = {
          full-at = 98;
          states.low = 20;
          interval = 60;
          format = "<span color='#F0C674'>{icon}</span> {capacity}%";
          format-charging = "<span color='#1AA81A'>{icon} {capacity}%</span>";
          format-full = "<span color='#1AA81A'></span>";
          format-low = "<span color='#E60000'> {capacity}% {time}</span>";
          format-time = "{H}:{m}";
          format-icons = [ "" "" "" "" "" ];
        };

        tray.spacing = 16;

        "custom/power" = {
          format = "";
          tooltip = false;
          on-click = "${powerMenu}/bin/sway-power-menu";
        };
      };
    };

    # Applies saved monitor layouts automatically on hotplug (docked vs
    # laptop). Profiles go in `settings` once the layouts are known — arrange
    # them in wdisplays, then record the result here.
    services.kanshi.enable = true;

    home.packages = with pkgs; [
      wdisplays # arandr-style drag-and-drop display layout GUI
      brightnessctl
    ];
  };
}
