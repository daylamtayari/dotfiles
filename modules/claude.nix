# modules/claude.nix — Claude Code user configuration.
#
# The claude-code package itself is installed via modules/profiles/dev.nix; this
# module only manages the global user config at ~/.claude/settings.json.
#
# ~/.claude is not an XDG path, and it is also a live state directory: Claude
# writes history, sessions, cache, projects, etc. underneath it, so the whole
# directory is NOT symlinked — only settings.json is managed. It is a real,
# writable file (mode 600, assembled at activation time like ~/.aws/config in
# modules/misc.nix) rather than a read-only Nix-store symlink, so Claude can
# still edit it in-app (e.g. /theme). Note that a rebuild re-copies the tracked
# version, so the git tree is the source of truth — persist changes by editing
# config/claude/settings.json.
#
# settings.json references the statusline via "~/.claude/statusline.sh": the
# statusLine command is run through a shell (so ~ expands) but with the working
# directory set to the current *project* dir, not ~/.claude — a relative path
# like ./statusline.sh would not resolve. The script itself is installed below
# as a read-only symlink into ~/.claude (it needs no in-app edits, unlike
# settings.json). jq — which the script depends on — comes from
# modules/profiles/core.nix.
#
# MCP servers: Claude Code does NOT read server definitions from settings.json
# (that file is MCP *policy* only). User-scoped servers live under the top-level
# "mcpServers" key of ~/.claude.json — a large, Claude-managed state file. So
# rather than copy it, we jq-merge our tracked server set into just that key,
# leaving everything else untouched. github uses OAuth (no token in git); nvim
# is the linw1995/nvim-mcp stdio server, whose binary comes from that project's
# own flake and lands on PATH via the Home Manager profile (modules/nvim.nix),
# spawned through the nvim-mcp-claude shim below. See
# config/claude/mcp-servers.json.
{ lib, pkgs, ... }:

{
  home.activation.claudeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeBase=${../config/claude/settings.json}
    claudeDest="$HOME/.claude/settings.json"
    if [ -n "''${DRY_RUN_CMD:-}" ]; then
      verboseEcho "Would install $claudeDest from config/claude/settings.json"
    else
      mkdir -p "$HOME/.claude"
      cp "$claudeBase" "$claudeDest"
      chmod 600 "$claudeDest"
    fi
  '';

  # Merge our declared MCP servers into ~/.claude.json's top-level "mcpServers"
  # without disturbing the rest of that Claude-managed file. jq writes to a temp
  # file and is only mv'd on success, so a malformed source or jq error can
  # never clobber the live config.
  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeMcp=${../config/claude/mcp-servers.json}
    claudeJson="$HOME/.claude.json"
    if [ -n "''${DRY_RUN_CMD:-}" ]; then
      verboseEcho "Would merge mcpServers into $claudeJson"
    else
      tmp="$(mktemp)"
      if [ -f "$claudeJson" ]; then
        ${pkgs.jq}/bin/jq --slurpfile s "$claudeMcp" '.mcpServers = $s[0]' \
          "$claudeJson" > "$tmp" && mv "$tmp" "$claudeJson"
      else
        ${pkgs.jq}/bin/jq -n --slurpfile s "$claudeMcp" '{mcpServers: $s[0]}' \
          > "$claudeJson"
      fi
      chmod 600 "$claudeJson"
    fi
  '';

  # Claude-only shim around nvim-mcp that fills in the 2026-07-28 list-result
  # cache fields Claude Code requires but nvim-mcp 0.7.2 omits; see the script's
  # docstring. opencode keeps spawning plain `nvim-mcp`.
  home.packages = [
    (pkgs.writers.writePython3Bin "nvim-mcp-claude" { }
      (builtins.readFile ../config/claude/nvim-mcp-claude.py))
  ];

  # Symlinked (not copied): the statusline script is not something Claude edits,
  # so a read-only store symlink is fine and keeps it in sync with the repo.
  home.file.".claude/statusline.sh" = {
    source = ../config/claude/statusline.sh;
    executable = true;
  };
}
