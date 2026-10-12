# modules/misc.nix — small standalone config files that have no dedicated
# Home Manager module, so they are plain symlinks rather than programs.*.
{ lib, ... }:

{
  # AWS CLI config. ~/.aws is not an XDG path. Credentials are not in this
  # repo — the AWS CLI writes ~/.aws/credentials itself.
  #
  # The AWS CLI has no `include` directive, so a profile's non-credential
  # settings (SSO URLs, account IDs, role_arn, region overrides, mfa_serial)
  # must live in ~/.aws/config itself. To keep sensitive per-profile settings
  # out of the git tree, ~/.aws/config is assembled at activation time from:
  #   1. the git-tracked defaults in config/aws/config, plus
  #   2. an optional local, un-tracked overlay at
  #      ${XDG_CONFIG_HOME:-~/.config}/aws/local.conf
  # The result is a real file — the secret overlay never enters git nor the
  # world-readable Nix store. Edits to local.conf take effect on the next
  # `darwin-rebuild switch`.
  #
  # No explicit chmod: ~/.aws/config holds no credentials (those live in the
  # separate ~/.aws/credentials, which the AWS CLI manages), so it takes the
  # default umask perms. A chmod here also aborted the switch whenever the file
  # was owned by another user (e.g. left root-owned by an earlier root-run
  # activation) — only the owner may chmod.
  home.activation.awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    awsBase=${../config/aws/config}
    awsLocal="''${XDG_CONFIG_HOME:-$HOME/.config}/aws/local.conf"
    awsDest="$HOME/.aws/config"
    if [ -n "''${DRY_RUN_CMD:-}" ]; then
      verboseEcho "Would assemble $awsDest from base + optional $awsLocal"
    else
      mkdir -p "$HOME/.aws"
      {
        cat "$awsBase"
        if [ -f "$awsLocal" ]; then
          printf '\n'
          cat "$awsLocal"
        fi
      } > "$awsDest"
    fi
  '';

  xdg.configFile = {
    # pycodestyle — Python style checker.
    "pycodestyle".source = ../config/pycodestyle;

    # VSCodium extension-gallery override (programs.vscode does not manage
    # product.json). Note: macOS VSCodium reads this from
    # ~/Library/Application Support/VSCodium/ instead — revisit in Phase 5.
    "VSCodium/product.json".source = ../config/VSCodium/product.json;
  };
}
