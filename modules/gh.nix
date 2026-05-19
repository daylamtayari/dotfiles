# modules/gh.nix — GitHub CLI.
#
# Converted from dot_config/gh/config.yml to the native programs.gh module.
# The old config's empty `editor` / `browser` / `http_unix_socket` fields are
# omitted — empty meant "use the default", which is what omitting them does.
# gh's auth tokens live in ~/.config/gh/hosts.yml, which gh manages itself.
{ ... }:

{
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };
}
