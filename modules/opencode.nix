# modules/opencode.nix — OpenCode agent configuration.
#
# OpenCode itself is installed out-of-band (Homebrew on macOS); this module only
# manages its config. Unlike Claude (~/.claude, a non-XDG live-state dir edited
# in-app — see modules/claude.nix), OpenCode reads $XDG_CONFIG_HOME/opencode/
# and opencode.jsonc is a user-authored config the app does not rewrite, so a
# read-only Nix-store symlink is the right fit (same idiom as aerospace.toml).
#
# Only opencode.jsonc is managed: OpenCode drops its own node_modules/,
# package.json and package-lock.json into the same directory for plugins, and
# the dir's own .gitignore already excludes them — so the directory as a whole
# is NOT symlinked, only this one file.
{ ... }:

{
  xdg.configFile."opencode/opencode.jsonc".source = ../config/opencode/opencode.jsonc;
}
