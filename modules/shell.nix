# modules/shell.nix — programs.zsh.
#
# Ports dot_config/zsh/{dot_zshrc,functions.zsh,p10k.zsh,aliases/} and the
# environment exports from dot_zshenv.tmpl. The alias/function/p10k trees are
# kept verbatim under config/zsh/ and symlinked into ZDOTDIR; the rest of the
# old .zshrc is expressed natively or moved into initContent.
{ config, pkgs, ... }:

{
  # Exports XDG_CONFIG_HOME / XDG_DATA_HOME / XDG_STATE_HOME / XDG_CACHE_HOME.
  # The non-standard XDG_BIN_HOME / XDG_LIB_HOME are added below.
  xdg.enable = true;

  # The old .zshrc ran `eval "$(zoxide init zsh)"`; zoxide was assumed to be
  # installed out-of-band (it is not in packages.yaml). programs.zoxide both
  # installs it and adds the init.
  programs.zoxide.enable = true;

  # Environment — replaces dot_zshenv.tmpl.
  home.sessionVariables = {
    # Default applications
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "bat";
    TERMINAL = "kitty";
    BROWSER = "firefox";

    # Non-standard XDG dirs (the standard four come from xdg.enable above).
    XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
    XDG_LIB_HOME = "${config.home.homeDirectory}/.local/lib";

    # Per-application config locations
    CURL_HOME = "${config.xdg.configHome}/curl";
    WGETRC = "${config.xdg.configHome}/wget/wgetrc";

    # Toolchain dirs
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    GOPATH = "${config.home.homeDirectory}/go";

    # Locale. The old dot_zshenv also set LC_ALL=C, which forces the C locale
    # and breaks UTF-8 collation/output — dropped deliberately; LANG governs.
    LANG = "en_US.UTF-8";

    # oh-my-zsh: keep the terminal title static. Set as a session variable so
    # it is exported before .zshrc (and therefore oh-my-zsh.sh) runs.
    DISABLE_AUTO_TITLE = "true";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.xdg.dataHome}/cargo/bin"
    "${config.home.homeDirectory}/go/bin"
    "${config.home.homeDirectory}/.pdtm/go/bin"
  ];

  # Raw zsh trees, kept verbatim and symlinked into ZDOTDIR (~/.config/zsh).
  xdg.configFile = {
    "zsh/aliases".source = ../config/zsh/aliases;
    "zsh/functions.zsh".source = ../config/zsh/functions.zsh;
    "zsh/p10k.zsh".source = ../config/zsh/p10k.zsh;
  };

  programs.zsh = {
    enable = true;

    # ZDOTDIR = ~/.config/zsh, matching the old dot_zshenv. (Home Manager
    # writes a ~/.zshenv that sets ZDOTDIR, so it is not exported manually.)
    dotDir = "${config.xdg.configHome}/zsh";

    # Replaces the oh-my-zsh `zsh-syntax-highlighting` / `zsh-autosuggestions`
    # custom plugins with the Home Manager-packaged equivalents.
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 100000;
      save = 100000;
      ignoreDups = true; # HIST_IGNORE_DUPS
      ignoreAllDups = true; # HIST_IGNORE_ALL_DUPS
      ignoreSpace = true; # HIST_IGNORE_SPACE
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    initContent = ''
      # --- Shell options ---
      setopt APPEND_HISTORY        # append to the history file
      setopt INC_APPEND_HISTORY    # ...incrementally, as commands are run
      setopt CORRECT               # offer spelling corrections
      setopt INTERACTIVE_COMMENTS  # allow comments in interactive shells

      # --- zle / completion helpers (compinit is run by Home Manager) ---
      autoload edit-command-line
      zle -N edit-command-line
      autoload -U colors && colors

      # --- Powerlevel10k ---
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f ${config.xdg.configHome}/zsh/p10k.zsh ]] || source ${config.xdg.configHome}/zsh/p10k.zsh

      # --- Miscellaneous ---
      export TERM=xterm-256color
      umask 027

      # --- Aliases & functions (raw trees from config/zsh/) ---
      if [[ -d ${config.xdg.configHome}/zsh/aliases ]]; then
        for alias_file in ${config.xdg.configHome}/zsh/aliases/*.zsh; do
          source "$alias_file"
        done
      fi
      source ${config.xdg.configHome}/zsh/functions.zsh

      # --- pyenv (the pyenv binary is expected to be installed out-of-band) ---
      export PYENV_ROOT="$HOME/.pyenv"
      [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
      if command -v pyenv >/dev/null; then
        eval "$(pyenv init - zsh)"
      fi
    '';
  };
}
