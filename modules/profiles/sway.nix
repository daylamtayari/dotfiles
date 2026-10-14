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
# power popup → a rofi power menu (the yad calendar stays). Qubes-only pieces
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

  lock = "${config.programs.swaylock.package}/bin/swaylock -f";
  pactlBin = "${pkgs.pulseaudio}/bin/pactl";
  brightnessctlBin = "${pkgs.brightnessctl}/bin/brightnessctl";
  swayncClient = "${config.services.swaync.package}/bin/swaync-client";

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
      choice=$(printf 'Lock\nSuspend\nHibernate\nShutdown\nReboot\nLogout\n' | rofi -dmenu -i -p "Power")
      case "$choice" in
        Lock) ${lock} ;;
        Suspend) systemctl suspend ;;
        Hibernate) systemctl hibernate ;;
        Shutdown) systemctl poweroff ;;
        Reboot) systemctl reboot ;;
        Logout) swaymsg exit ;;
      esac
    '';
  };

  # Click-to-toggle calendar under the Waybar clock — the i3-era yad popup.
  # Waybar's own calendar is a tooltip, so it vanishes when the pointer leaves
  # and can't be clicked. The for_window rule below floats it; Wayland gives
  # clients no say in placement, so it's moved here once mapped: centered
  # horizontally, just below the bar (workspace coordinates already exclude
  # Waybar's exclusive zone). Closes on Esc, on losing focus, or on a second
  # click (clicking the bar doesn't take keyboard focus from it).
  calendarPopup = pkgs.writeShellApplication {
    name = "sway-calendar-popup";
    runtimeInputs = [ pkgs.yad pkgs.jq pkgs.procps ];
    text = ''
      if pkill -u "$USER" -f '^yad --calendar --title=yad-calendar'; then
        exit 0
      fi
      yad --calendar --title=yad-calendar --undecorated --no-buttons --borders=0 \
        --close-on-unfocus --show-weeks >/dev/null &
      pid=$!
      for _ in $(seq 100); do
        width=$(swaymsg -t get_tree | jq -r --argjson pid "$pid" \
          'first(.. | objects | select(.pid? == $pid) | .rect.width) // empty')
        [ -n "$width" ] && break
        sleep 0.02
      done
      [ -n "$width" ] || exit 0
      wsWidth=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .rect.width')
      swaymsg "[pid=$pid] move position $(( (wsWidth - width) / 2 )) 4" >/dev/null
    '';
  };

  # Waybar connectivity indicator. The built-in network module tracks a single
  # interface, so it can't show wired and wireless at once; ask NetworkManager
  # instead. Icons only in the bar; the tooltip lists the active connection
  # names (for Wi-Fi, NetworkManager names the profile after the SSID).
  networkStatus = pkgs.writeShellApplication {
    name = "waybar-network-status";
    runtimeInputs = [ pkgs.networkmanager pkgs.jq ];
    text = ''
      eth=0 wifi=0 lines=()
      # Terse output escapes ':' in values as '\:' — CONNECTION is last, so
      # read takes the rest of the line and the escapes are undone after.
      while IFS=: read -r type state name; do
        case "$state" in connected*) ;; *) continue ;; esac
        name=''${name//\\:/:}
        case "$type" in
          ethernet) eth=1 lines+=("Ethernet: $name") ;;
          wifi) wifi=1 lines+=("Wi-Fi: $name") ;;
        esac
      done < <(nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null || true)

      case "$eth$wifi" in
        11) icons="󰈀 󰖩" ;;
        10) icons="󰈀" ;;
        01) icons="󰖩" ;;
        *)
          printf '{"text":"<span color=\x27#707880\x27>󰖪</span>","tooltip":"Disconnected","class":"disconnected"}\n'
          exit 0
          ;;
      esac
      # Tooltips are Pango markup, so escape the (user-controlled) names.
      printf '%s\n' "''${lines[@]}" | jq -Rsc --arg icons "$icons" '{
        text: "<span color=\"#F0C674\">\($icons)</span>",
        tooltip: (rtrimstr("\n") | gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;")),
        class: "connected"
      }'
    '';
  };

  # Waybar Tailscale indicator — lit while the backend is Running.
  tailscaleStatus = pkgs.writeShellApplication {
    name = "waybar-tailscale-status";
    runtimeInputs = [ pkgs.tailscale pkgs.jq ];
    text = ''
      state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // "Unknown"') || state=Unavailable
      if [ "$state" = Running ]; then
        printf '{"text":"<span color=\x27#F0C674\x27>󰖂</span>","tooltip":"Tailscale: up","class":"up"}\n'
      else
        printf '{"text":"<span color=\x27#707880\x27>󰖂</span>","tooltip":"Tailscale: %s","class":"down"}\n' "$state"
      fi
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

  # Window colors from the Waybar palette (config/waybar/style.css).
  # childBorder is the visible 1px border, since titlebars are off.
  palette = border: background: text: indicator: childBorder: {
    inherit border background text indicator childBorder;
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
          size = 10.0; # as in the i3 config — keeps tabbed/stacked titles minimal
        };

        gaps = {
          inner = 8;
          outer = 0;
        };
        window = {
          border = 1;
          titlebar = false;
        };
        floating = {
          border = 1;
          titlebar = false;
        };

        colors = {
          background = "#282A2E"; # background
          focused = palette "#F0C674" "#373B41" "#C5C8C6" "#F0C674" "#F0C674"; # primary accent
          focusedInactive = palette "#373B41" "#373B41" "#C5C8C6" "#373B41" "#373B41"; # background-alt
          unfocused = palette "#282A2E" "#282A2E" "#707880" "#282A2E" "#282A2E"; # background / disabled
          urgent = palette "#A54242" "#A54242" "#C5C8C6" "#A54242" "#A54242"; # alert
        };

        # feh replacement. Missing file → sway shows a config error bar; drop
        # a wallpaper at this path (or change it).
        # subpixel is advertised to clients over wl_output (GTK reads it) and
        # used for sway's own title text. All monitors here are RGB-stripe.
        output."*" = {
          bg = "~/Pictures/wallpaper.png fill";
          subpixel = "rgb";
        };

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

          # Notifications (swaync)
          "${mod}+n" = "exec ${swayncClient} -t -sw"; # toggle notification center
          "${mod}+Shift+n" = "exec ${swayncClient} -d -sw"; # toggle do-not-disturb

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

        # Calendar popup from the Waybar clock (calendarPopup above).
        for_window [app_id="yad" title="^yad-calendar$"] floating enable

        # Blank the internal panel while the lid is shut. Mostly moot while
        # logind suspends on docked lid close (nixos/work/default.nix), but
        # takes over if HandleLidSwitchDocked is set to "ignore" or sleep is
        # inhibited. --reload re-applies the current lid state on reload.
        bindswitch --reload --locked lid:on output eDP-1 disable
        bindswitch --reload --locked lid:off output eDP-1 enable

        # SwayFX-only — replaces picom's rounded corners. Plain sway would
        # reject this line.
        corner_radius 8
      '';
    };

    # xss-lock + betterlockscreen replacement. X's default screensaver fired
    # xss-lock after 10 minutes idle; betterlockscreen's `--off 600` blanked the
    # display 10 minutes after that.
    # swaylock-effects fork for the clock; plain swaylock has no --clock.
    # Black screen with the time/date always shown; the ring stays invisible
    # until typing (key/backspace highlights) or verifying/failing. The clock
    # is drawn inside the indicator, so the radius bounds the text size — keep
    # it large.
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        color = "000000";
        clock = true;
        indicator = true; # always draw the indicator, so the clock stays up
        indicator-radius = 120;
        indicator-thickness = 6;
        hide-keyboard-layout = true;
        timestr = "%H:%M";
        datestr = "%a %d %b";
        font = "FiraCode Nerd Font";
        font-size = 48;
        text-color = "C5C8C6";
        text-clear-color = "C5C8C6";
        text-ver-color = "C5C8C6";
        text-wrong-color = "A54242";
        inside-color = "00000000";
        inside-clear-color = "00000000";
        inside-ver-color = "00000000";
        inside-wrong-color = "00000000";
        ring-color = "00000000";
        ring-clear-color = "00000000";
        ring-ver-color = "F0C674";
        ring-wrong-color = "A54242";
        line-color = "00000000";
        line-clear-color = "00000000";
        line-ver-color = "00000000";
        line-wrong-color = "00000000";
        separator-color = "00000000";
        key-hl-color = "F0C674";
        bs-hl-color = "A54242";
        inside-caps-lock-color = "00000000";
        ring-caps-lock-color = "00000000";
        line-caps-lock-color = "00000000";
        caps-lock-key-hl-color = "F0C674";
        caps-lock-bs-hl-color = "A54242";
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
        modules-right = [ "bluetooth" "pulseaudio" "custom/network" "custom/tailscale" "memory" "cpu" "battery" "tray" "custom/notification" "custom/power" ];

        "sway/workspaces" = {
          all-outputs = false; # polybar pin-workspaces = true
          disable-scroll = false;
        };

        # popup-calendar + hyphen + time. Click opens the yad calendar popup.
        clock = {
          interval = 1;
          format = "{0:%A, %B %d} <span color='#707880'>—</span> {0:%H:%M}";
          tooltip = false;
          on-click = "${calendarPopup}/bin/sway-calendar-popup";
        };

        pulseaudio = {
          format = "<span color='#F0C674'>{icon}</span> {volume}%";
          format-muted = "<span color='#F0C674'>󰝟</span> muted";
          format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
          on-click = "${pactlBin} set-sink-mute @DEFAULT_SINK@ toggle";
          on-click-right = "pavucontrol";
        };

        # Wired / wireless / none — see networkStatus above.
        "custom/network" = {
          exec = "${networkStatus}/bin/waybar-network-status";
          return-type = "json";
          interval = 5;
        };

        "custom/tailscale" = {
          exec = "${tailscaleStatus}/bin/waybar-tailscale-status";
          return-type = "json";
          interval = 5;
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

        # Hidden when there is no Bluetooth controller. Click opens Blueman.
        bluetooth = {
          format = "<span color='#F0C674'>󰂯</span>";
          format-disabled = "<span color='#707880'>󰂲</span>";
          format-off = "<span color='#707880'>󰂲</span>";
          format-connected = "<span color='#F0C674'>󰂱</span> {device_alias}";
          format-connected-battery = "<span color='#F0C674'>󰂱</span> {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}: {status}";
          tooltip-format-connected = "{controller_alias}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          on-click = "blueman-manager";
        };

        tray.spacing = 16;

        # swaync bell — badge when there are unread notifications, crossed out
        # in do-not-disturb. -swb streams state changes as JSON (`alt` picks
        # the icon). Click toggles the center, right-click toggles DND.
        "custom/notification" = {
          exec = "${swayncClient} -swb";
          return-type = "json";
          escape = true;
          tooltip = false;
          format = "{icon}";
          format-icons = {
            none = "<span color='#F0C674'>󰂚</span>";
            notification = "<span color='#F0C674'>󱅫</span>";
            dnd-none = "<span color='#707880'>󰂛</span>";
            dnd-notification = "<span color='#707880'>󰂛</span>";
            inhibited-none = "<span color='#F0C674'>󰂚</span>";
            inhibited-notification = "<span color='#F0C674'>󱅫</span>";
            dnd-inhibited-none = "<span color='#707880'>󰂛</span>";
            dnd-inhibited-notification = "<span color='#707880'>󰂛</span>";
          };
          on-click = "${swayncClient} -t -sw";
          on-click-right = "${swayncClient} -d -sw";
        };

        "custom/power" = {
          format = "";
          tooltip = false;
          on-click = "${powerMenu}/bin/sway-power-menu";
        };
      };
    };

    # Text rendering. Every output runs at scale 1, so text needs hinting and
    # subpixel AA to look sharp — NixOS's default is grayscale (rgba none),
    # which reads as soft on the 4Ks. Applies to Firefox, Thunderbird, GTK3
    # and Chromium/Electron apps, which all read fontconfig.
    fonts.fontconfig = {
      antialiasing = true;
      hinting = "slight";
      subpixelRendering = "rgb";
      # fontconfig's metric aliases map Helvetica to TeX Gyre Heros first, a
      # CFF font with weak hinting that renders fuzzy at UI sizes. Mail and
      # web content ask for Helvetica constantly; prefer Liberation Sans
      # (same metrics, properly hinted TrueType).
      configFile.helvetica = {
        enable = true;
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <alias binding="same">
              <family>Helvetica</family>
              <prefer><family>Liberation Sans</family></prefer>
            </alias>
          </fontconfig>
        '';
      };
    };

    # Super Productivity injects <userData>/styles.css into its window; used
    # to swap its unhinted bundled webfont for the system UI font.
    xdg.configFile."superProductivity/styles.css".source =
      ../../config/superproductivity/styles.css;

    gtk = {
            enable = true;
            colorScheme = "dark";
            # The "No desktop" install ships no icon theme (only the empty
            # hicolor fallback), so symbolic icons — e.g. the swaync media
            # controls — were missing.
            iconTheme = {
              name = "Adwaita";
              package = pkgs.adwaita-icon-theme;
            };
            # UI font for GTK apps and Thunderbird/Firefox chrome. Unset, GTK
            # falls back to "Sans 10" = 13.33px at 96 DPI; fractional pixel
            # sizes can't snap to the grid when hinted and look fuzzy.
            # 10.5pt = exactly 14px.
            font = {
              name = "Noto Sans";
              size = 10.5;
            };
            # GTK 4.16+ ignores fontconfig hinting and positions glyphs at
            # fractional offsets by default, which blurs text at 1x. "manual"
            # makes it honour the gtk-xft-* settings below.
            gtk3.extraConfig = {
              gtk-xft-antialias = 1;
              gtk-xft-hinting = 1;
              gtk-xft-hintstyle = "hintslight";
              gtk-xft-rgba = "rgb";
            };
            gtk4.extraConfig = {
              gtk-font-rendering = "manual";
              gtk-hint-font-metrics = true;
              gtk-xft-antialias = 1;
              gtk-xft-hinting = 1;
              gtk-xft-hintstyle = "hintslight";
              gtk-xft-rgba = "rgb";
            };
        };
    # Cursor theme. Unset, apps fall back to Adwaita's (or X's core) cursors,
    # whose hand pointer looks rough. Bibata ships every XCursor size from 16
    # to 96px, so it stays sharp if an output's scale is raised. Sets
    # XCURSOR_THEME/SIZE, GTK's cursor settings and sway's `seat * xcursor_theme`
    # so all clients and sway itself agree.
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Classic";
      size = 20;
      gtk.enable = true;
      x11.enable = true; # XWayland apps
      sway.enable = true;
    };

    qt = {
            enable = true;
            platformTheme.name = "adwaita";
            style.name = "adwaita-dark";
        };

    # Applies saved monitor layouts automatically on hotplug (docked vs
    # laptop). Profiles go in `settings` once the layouts are known — arrange
    # them in wdisplays, then record the result here.
    services.kanshi.enable = true;
    
    # Polkit authentication agent — shows the password/fingerprint prompt for
    # actions marked auth_self/auth_admin. Sway has none built in, so without
    # it polkit just denies them (`fprintd-enroll`, 1Password's system unlock,
    # blueman/NetworkManager admin actions).
    services.polkit-gnome.enable = true;

    # Notification daemon + slide-out notification center (mod+n). Runs as a
    # systemd user service tied to Sway's graphical-session.target. Unset keys
    # keep swaync's built-in defaults. The user stylesheet replaces the
    # packaged one rather than layering on it, so the default is imported first
    # and config/swaync/style.css only recolors it.
    services.swaync = {
      enable = true;
      settings = {
        positionX = "right";
        positionY = "top";
        control-center-margin-top = 8;
        control-center-margin-right = 8;
        control-center-margin-bottom = 8;
        timeout = 8;
        timeout-low = 4;
        timeout-critical = 0; # critical stays until dismissed
        widgets = [ "title" "dnd" "mpris" "notifications" ];
        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear";
          };
          dnd.text = "Do Not Disturb";
        };
      };
      style = ''
        @import url("file://${config.services.swaync.package}/etc/xdg/swaync/style.css");
      '' + builtins.readFile ../../config/swaync/style.css;
    };

    home.packages = with pkgs; [
      wdisplays # arandr-style drag-and-drop display layout GUI
      brightnessctl
    ];
  };
}
