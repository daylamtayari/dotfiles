# modules/misc.nix — small standalone config files that have no dedicated
# Home Manager module, so they are plain symlinks rather than programs.*.
{ ... }:

{
  # AWS CLI — region/output defaults. ~/.aws is not an XDG path. (Credentials
  # are not in this repo; the AWS CLI writes ~/.aws/credentials itself.)
  home.file.".aws/config".source = ../config/aws/config;

  xdg.configFile = {
    # pycodestyle — Python style checker.
    "pycodestyle".source = ../config/pycodestyle;

    # VSCodium extension-gallery override (programs.vscode does not manage
    # product.json). Note: macOS VSCodium reads this from
    # ~/Library/Application Support/VSCodium/ instead — revisit in Phase 5.
    "VSCodium/product.json".source = ../config/VSCodium/product.json;
  };
}
