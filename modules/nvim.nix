# modules/nvim.nix — Neovim.
#
# The lazy.nvim / NvChad Lua tree is NOT translated to Nix (explicitly out of
# scope per NIX_MIGRATION.md) — it is symlinked verbatim from config/nvim/.
{ pkgs, inputs, ... }:

{
  home.packages = [
    pkgs.neovim

    # The nvim-mcp *server* binary. Clients (Claude Code's "nvim" entry in
    # config/claude/mcp-servers.json, opencode's in config/opencode/opencode.jsonc)
    # spawn it as plain `nvim-mcp`, resolved off PATH via the HM profile. The
    # matching Lua plugin is installed by lazy.nvim — see
    # config/nvim/lua/plugins/mcp.lua, which starts the RPC socket this binary
    # discovers.
    inputs.nvim-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # `recursive` makes ~/.config/nvim a real directory of per-file symlinks
  # rather than one symlink to the read-only store. This lets Neovim and
  # lazy.nvim write runtime files (notably lazy-lock.json) into the config
  # directory, which a single store symlink would forbid.
  xdg.configFile."nvim" = {
    source = ../config/nvim;
    recursive = true;
  };
}
