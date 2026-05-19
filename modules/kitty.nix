# modules/kitty.nix — programs.kitty.
#
# The hand-maintained kitty.conf is kept verbatim under config/kitty/ and fed
# in via extraConfig rather than being translated to programs.kitty.settings —
# this preserves the file's comments and fold markers as the user maintains
# them. programs.kitty still installs the package and owns ~/.config/kitty.
{ ... }:

{
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ../config/kitty/kitty.conf;
  };
}
