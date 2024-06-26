# Alias Tips
# Credit @Lissy93
# If an alias for the command just run exists, then show tip

preexec_alias-finder() {
  tip=$(alias | grep -E "=$1$" | head -1)
  if [ ! -z "$tip" ]; then
    echo -e "\033[0;90m\e[3mAlias Tip: \e[4m$tip\033[0m"
  fi
}

autoload -U add-zsh-hook

add-zsh-hook preexec preexec_alias-finder
