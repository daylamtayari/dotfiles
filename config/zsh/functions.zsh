# Functions

function ndir() {
    mkdir -p $1; cd $1
}

# Diff a single commit against its parent. Defaults to HEAD.
# Extra args pass through to git diff:
#   comdiff                     # HEAD vs its parent
#   comdiff HEAD~3 --stat
#   comdiff abc123 -- path/to/file
function comdiff() {
  emulate -L zsh

  # Only treat the first arg as the revision if it isn't a flag or `--`, so
  # `comdiff --stat` still means "HEAD, with --stat".
  local rev=HEAD
  if (( $# )) && [[ $1 != -* ]]; then
    rev=$1
    shift
  fi

  if ! git rev-parse --verify --quiet "$rev^{commit}" >/dev/null; then
    print -u2 "comdiff: not a commit: $rev"
    return 1
  fi

  # ^! means "this commit vs its parent(s)" and, unlike <rev>~, works on the
  # root commit.
  git diff "$rev^!" "$@"
}

# Turn a JSON blob that was stringified/escaped (e.g. copied out of a log
# field) back into valid, pretty-printed JSON. Reads from stdin.
#   pbpaste | unjson
#   unjson < alert.txt
#   pbpaste | unjson -c '.projects[].name'   # extra args go to jq
function unjson() {
  emulate -L zsh
  setopt extended_glob

  if (( ! $+commands[jq] )); then
    print -u2 "unjson: jq not found in PATH"
    return 1
  fi

  local -a jq_args=("$@")
  (( $#jq_args )) || jq_args=('.')

  local data=$(cat)
  data=${data##[[:space:]]##}
  data=${data%%[[:space:]]##}

  if [[ -z $data ]]; then
    print -u2 "unjson: no input on stdin"
    return 1
  fi

  # If the surrounding quotes were lost on the way to the clipboard, add them
  # back so jq will decode the \" escapes.
  if ! print -r -- "$data" | jq empty >/dev/null 2>&1; then
    if ! print -r -- "\"$data\"" | jq empty >/dev/null 2>&1; then
      print -u2 "unjson: input is not valid JSON (with or without outer quotes)"
      return 1
    fi
    data="\"$data\""
  fi

  # Peel off every layer of string encoding, stopping as soon as the payload
  # is no longer a string that itself holds JSON.
  local depth=0 inner
  while (( depth++ < 10 )); do
    [[ $(print -r -- "$data" | jq -r 'type' 2>/dev/null) == string ]] || break
    inner=$(print -r -- "$data" | jq -r '.') || break
    print -r -- "$inner" | jq empty >/dev/null 2>&1 || break
    data=$inner
  done

  print -r -- "$data" | jq "${jq_args[@]}"
}

# Assume OrganizationAccountAccessRole in a member account and export the
# resulting credentials into the current shell. Session lasts 900s.
#   assume-aws-admin 999999999999 dtayari-testing-123
#   aws sts get-caller-identity
function assume-aws-admin() {
  emulate -L zsh

  local account=$1 session=$2

  if [[ -z $account || -z $session ]]; then
    print -u2 "usage: assume-aws-admin <account-id> <session-name>"
    return 1
  fi

  if [[ $account != <-> ]]; then
    print -u2 "assume-aws-admin: account id must be numeric: $account"
    return 1
  fi

  if (( ! $+commands[aws] )); then
    print -u2 "assume-aws-admin: aws not found in PATH"
    return 1
  fi

  local role_arn="arn:aws:iam::${account}:role/OrganizationAccountAccessRole"

  # Pull the three values out in a fixed order so they can be read positionally.
  local creds
  if ! creds=$(aws sts assume-role \
      --role-arn "$role_arn" \
      --role-session-name "$session" \
      --duration-seconds 900 \
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
      --output text); then
    if [[ -n $AWS_SESSION_TOKEN ]]; then
      print -u2 "assume-aws-admin: credentials for a previous session are still exported; run 'unassume-aws' first"
    fi
    return 1
  fi

  local -a parts=(${(ps:\t:)creds})
  if (( $#parts != 3 )); then
    print -u2 "assume-aws-admin: unexpected response from sts assume-role"
    return 1
  fi

  export AWS_ACCESS_KEY_ID=$parts[1]
  export AWS_SECRET_ACCESS_KEY=$parts[2]
  export AWS_SESSION_TOKEN=$parts[3]

  print -r -- "[+] Assumed $role_arn as $session (expires in 15m)"
}

# Drop credentials exported by assume-aws-admin and fall back to whatever the
# shared config/profile provides.
function unassume-aws() {
  emulate -L zsh
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

function calcpps() {
  ips=$1
  ports=$2
  hours=$3
  total_scans=$((ips*ports))
  total_seconds=$((hours*3600))

  if [ $# -eq 3 ]; then
    pps=$(echo "scale=2; $total_scans / $total_seconds" | bc)
    echo "[*] Recommended to not exceed 5,000 pps for large scopes and 1,000 packets for smaller scopes"
    echo "[*] Taking the IP addresses, ports, and time available, recommended pps is:"
    echo "[+] Approximate packets per second (pps) SYN scans: $((pps * 2))"
    echo "[+] Approximate packets per second (pps) CONNECT scans: $((pps * 3))"
  elif [ $# -eq 2 ]; then
    pinnedppsminutes=$((total_scans / (1000 * 60)))
    pinnedppshours=$((total_scans / (1000 * 3600)))
    echo "[+] With 1000 pps the provided IPs and ports would take: approximately $pinnedppshours hour and $pinnedppsminutes minutes with no retries"
    echo "naabu has 3 retries by default and nmap -T4 has 6 retries."
  else
    echo "calcpps takes arg1 as IPs to scan, arg2 as amount of ports, a blank or arg3 or amount of time in hours to get a packets per second rate"
  fi
}
