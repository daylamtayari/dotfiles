# modules/mcphub.nix — MCP server registry for mcphub.nvim.
#
# mcphub.nvim (see config/nvim/lua/plugins/mcphub.lua) reads its MCP servers
# from $XDG_CONFIG_HOME/mcphub/servers.json. mcphub actively manages this file
# (marketplace installs, UI add/edit, per-server disabled/OAuth state), so it is
# a real, writable file assembled at activation time — like ~/.claude/settings.json
# (modules/claude.nix) and ~/.aws/config (modules/misc.nix) — rather than a
# read-only Nix-store symlink which mcphub could not write to.
#
# A rebuild re-copies the tracked version, so the git tree is the source of
# truth: persist server changes by editing config/mcphub/servers.json. The
# github server uses OAuth (PKCE) — no token is stored here; mcphub runs the
# auth flow on first use.
{ lib, ... }:

{
  home.activation.mcphubServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mcphubBase=${../config/mcphub/servers.json}
    mcphubDir="''${XDG_CONFIG_HOME:-$HOME/.config}/mcphub"
    mcphubDest="$mcphubDir/servers.json"
    if [ -n "''${DRY_RUN_CMD:-}" ]; then
      verboseEcho "Would install $mcphubDest from config/mcphub/servers.json"
    else
      mkdir -p "$mcphubDir"
      cp "$mcphubBase" "$mcphubDest"
      chmod 600 "$mcphubDest"
    fi
  '';
}
