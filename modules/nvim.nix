# modules/nvim.nix — Neovim.
#
# The lazy.nvim / NvChad Lua tree is NOT translated to Nix (explicitly out of
# scope per NIX_MIGRATION.md) — it is symlinked verbatim from config/nvim/.
{ pkgs, ... }:

{
  home.packages = [ pkgs.neovim ];

  # `recursive` makes ~/.config/nvim a real directory of per-file symlinks
  # rather than one symlink to the read-only store. This lets Neovim and
  # lazy.nvim write runtime files (notably lazy-lock.json) into the config
  # directory, which a single store symlink would forbid.
  xdg.configFile."nvim" = {
    source = ../config/nvim;
    recursive = true;
  };
}
