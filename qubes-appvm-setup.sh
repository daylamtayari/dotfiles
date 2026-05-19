#!/usr/bin/env bash
#
# qubes-appvm-setup.sh — make /nix persist in a Qubes AppVM.
#
# A Qubes AppVM's root filesystem (and therefore /nix) is volatile: it is
# reset from the template on every shutdown. This script registers /nix as a
# Qubes bind-dir, so the Nix store lives in the VM's private volume (/rw) and
# survives reboots.
#
# Run ONCE per AppVM, BEFORE installing Nix. A reboot is required afterwards
# to activate the bind-dir.

set -euo pipefail

readonly BIND_DIRS_D="/rw/config/qubes-bind-dirs.d"
readonly CONF="${BIND_DIRS_D}/50_nix.conf"
readonly STORE="/rw/bind-dirs/nix"
readonly BIND_LINE="binddirs+=( /nix )"

info() { printf '\033[36m::\033[0m %s\n' "$*"; }
ok() { printf '\033[32mok:\033[0m %s\n' "$*"; }
err() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; }

# --- preconditions --------------------------------------------------------

# /rw is the Qubes private-volume mount; /usr/lib/qubes ships with the
# qubes-core-agent. Both present => almost certainly inside a Qubes VM.
if [ ! -d /rw ] || [ ! -d /usr/lib/qubes ]; then
    err "this does not look like a Qubes VM (/rw or /usr/lib/qubes missing)."
    err "aborting — nothing was changed."
    exit 1
fi

# /rw/config is root-owned; re-exec under sudo if not already root.
if [ "$(id -u)" -ne 0 ]; then
    info "elevating with sudo..."
    exec sudo -- "$(readlink -f "$0")" "$@"
fi

# --- apply (idempotent) ---------------------------------------------------

if [ -f "$CONF" ] && grep -qF "$BIND_LINE" "$CONF"; then
    ok "bind-dir already configured: $CONF"
else
    info "creating $BIND_DIRS_D"
    mkdir -p "$BIND_DIRS_D"
    info "writing $CONF"
    printf '%s\n' "$BIND_LINE" >"$CONF"
    chmod 0644 "$CONF"
    ok "bind-dir entry written: $CONF"
fi

# Pre-create the persistent store dir so the first post-reboot boot has a
# directory to bind-mount onto /nix.
if [ ! -d "$STORE" ]; then
    info "creating persistent store dir $STORE"
    mkdir -p "$STORE"
fi
ok "persistent store dir present: $STORE"

# --- next steps -----------------------------------------------------------

cat <<'EOF'

/nix is registered as a Qubes bind-dir. It is NOT active until the next reboot.

Next steps, in this VM:
  1. Reboot so the bind-dir takes effect.
  2. Install Nix (single-user — no daemon, nothing on the volatile root):
       sh <(curl -L https://nixos.org/nix/install) --no-daemon
  3. Enable flakes:
       mkdir -p ~/.config/nix
       echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
  4. Apply the Home Manager config (.#dev or .#cyber):
       cd ~/.local/share/chezmoi
       nix run home-manager -- switch --flake .#<host>
  5. Reboot again; confirm `nix --version` and `home-manager generations`
     both survive.

If /nix fails to mount after the reboot, create the mountpoint in the
TEMPLATE VM (`sudo mkdir /nix`), then reboot this AppVM again.
EOF

reply=""
read -rp $'\nReboot now? [y/N] ' reply || true
case "$reply" in
[yY] | [yY][eE][sS])
    info "rebooting..."
    reboot
    ;;
*)
    info "not rebooting — reboot before installing Nix."
    ;;
esac
