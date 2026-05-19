# modules/ranger.nix — programs.ranger.
#
# rc.conf is kept verbatim under config/ranger/ and fed in via extraConfig.
# The ranger_devicons plugin comes from the `ranger-devicons` flake input
# (pinned in flake.lock), replacing the chezmoi git-repo external.
{ inputs, ... }:

{
  programs.ranger = {
    enable = true;
    extraConfig = builtins.readFile ../config/ranger/rc.conf;
    plugins = [
      {
        name = "ranger_devicons";
        src = inputs.ranger-devicons;
      }
    ];
  };

  # scope.sh — ranger's file preview script (rc.conf points preview_script at
  # ~/.config/ranger/scope.sh). chezmoi's `executable_` prefix made it +x on
  # apply; `executable = true` reproduces that for the symlinked store copy.
  xdg.configFile."ranger/scope.sh" = {
    source = ../config/ranger/scope.sh;
    executable = true;
  };
}
