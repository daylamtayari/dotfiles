# File and Directory Handling Aliases

# Directory Aliases
alias -g ...="../.."
alias -g ....="../../.."
alias -g .....="../../../.."
alias -g ......="../../../../.."
alias -g .......="../../../../../.."
alias -g ........="../../../../../../.."

# Temporary File and Directory Aliases
alias tempdir="cd $(mktemp -d)"
alias tempfile="nvim $(mktemp)"
