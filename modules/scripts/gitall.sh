#!/usr/bin/env bash
#
# gitall.sh — recursively find every Git repository below a directory and run a
# command in each, in parallel. A pure-shell reimplementation of
# mattmahn/gitall.rs (https://github.com/mattmahn/gitall.rs).
#
# Behavior mirrored from the Rust original:
#   * a "repo" is any directory containing a .git subdirectory; once found, its
#     subtree is pruned (nested repos / submodules are not descended into);
#   * the regex filters on the directory *name* by default, or the full
#     canonical path with --full-path;
#   * when running `git` and the command names a color-aware subcommand
#     (branch, diff, log, …), --color=<mode> is appended;
#   * each repo's output prints as an atomic block with a bold/underlined
#     header — green on success, red on failure.

set -u

# --------------------------------------------------------------------------
# Worker mode: the parent re-invokes this script once per repo via xargs so it
# can fan out across CPUs. The repo path is the LAST argument; everything
# between the sentinel and it is the command to run. Config arrives via the
# GA_* environment variables exported by the parent.
# --------------------------------------------------------------------------
if [ "${1:-}" = "--__gitall_worker" ]; then
  shift
  args=( "$@" )
  n=${#args[@]}
  repo=${args[$((n - 1))]}
  unset 'args[$((n - 1))]'
  cmd=( "${args[@]}" )

  # git --color=<mode> injection, decided once by the parent.
  if [ -n "${GA_COLOR_ARG:-}" ] && [ "$GA_EXEC" = git ]; then
    cmd+=( "$GA_COLOR_ARG" )
  fi

  td=$(mktemp -d "${TMPDIR:-/tmp}/gitall-w.XXXXXX")
  ( cd "$repo" && exec "$GA_EXEC" "${cmd[@]}" ) >"$td/out" 2>"$td/err"
  status=$?

  # Acquire the output mutex (mkdir is atomic and portable — no flock needed on
  # macOS) so each repo's block prints without interleaving with siblings.
  while ! mkdir "$GA_LOCKDIR" 2>/dev/null; do sleep 0.02; done

  if [ "$GA_HEADER_COLOR" = 1 ]; then
    if [ "$status" -eq 0 ]; then hdr=$'\033[1;4;32m'; else hdr=$'\033[1;4;31m'; fi
    printf '%s%s%s\n' "$hdr" "$repo" $'\033[0m'
  else
    printf '%s\n' "$repo"
  fi
  cat "$td/out"
  cat "$td/err" >&2
  printf '\n'

  rmdir "$GA_LOCKDIR" 2>/dev/null
  rm -rf "$td"
  exit 0
fi

# --------------------------------------------------------------------------
# Parent mode
# --------------------------------------------------------------------------
prog=${0##*/}
version="gitall.sh (gitall.rs reimplementation) 0.6.0"

# Defaults match gitall.
directory="."
max_depth=""
regex=".*"
full_path=0
follow=0
executable="git"
threads=""
color="auto"

usage() {
  cat <<EOF
Executes git(1) commands in repos below a parent directory

USAGE:
    $prog [FLAGS] [OPTIONS] [--] <COMMAND>...

FLAGS:
    -L, --follow              Follow symbolic links while walking
        --full-path           Match REGEX against the full canonical path
    -h, --help                Print help
    -V, --version             Print version

OPTIONS:
        --color <WHEN>        always | auto | never  [default: auto]
    -D, --directory <DIR>     Directory to start under    [default: .]
    -X, --executable <PROG>   Program to run in each repo  [default: git]
    -d, --max-depth <N>       Descend at most N directories below DIR
    -r, --regex <REGEX>       Only repos whose name matches REGEX [default: .*]
    -j, --threads <N>         Max commands to run in parallel [default: CPUs]

ARGS:
    <COMMAND>...              The command to run in each repo. To pass options
                              to it (e.g. -va), put them after --.
EOF
}

COMMAND=()
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)        usage; exit 0;;
    -V|--version)     printf '%s\n' "$version"; exit 0;;
    -L|--follow)      follow=1; shift;;
    --full-path)      full_path=1; shift;;
    --color)          color=$2; shift 2;;
    --color=*)        color=${1#*=}; shift;;
    -D|--directory)   directory=$2; shift 2;;
    --directory=*)    directory=${1#*=}; shift;;
    -X|--executable)  executable=$2; shift 2;;
    --executable=*)   executable=${1#*=}; shift;;
    -d|--max-depth)   max_depth=$2; shift 2;;
    --max-depth=*)    max_depth=${1#*=}; shift;;
    -r|--regex)       regex=$2; shift 2;;
    --regex=*)        regex=${1#*=}; shift;;
    -j|--threads)     threads=$2; shift 2;;
    --threads=*)      threads=${1#*=}; shift;;
    --)               shift; COMMAND+=( "$@" ); break;;
    -*)               printf '%s: unknown option %s\n' "$prog" "$1" >&2; exit 2;;
    *)                COMMAND+=( "$1" ); shift;;
  esac
done

if [ ${#COMMAND[@]} -eq 0 ]; then
  printf '%s: a <COMMAND> is required\n\n' "$prog" >&2
  usage >&2
  exit 2
fi

if [ -z "$threads" ]; then
  threads=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)
fi

# Resolve the color mode (true/false are gitall aliases for always/never).
case "$color" in
  always|true)  cmode=always;;
  never|false)  cmode=never;;
  *)            cmode=auto;;
esac
if [ "$cmode" = always ]; then
  header_color=1
elif [ "$cmode" = never ]; then
  header_color=0
elif [ -t 1 ]; then
  header_color=1
else
  header_color=0
fi

# Decide whether to inject git's --color (only for color-aware subcommands).
color_arg=""
if [ "$executable" = git ]; then
  for t in "${COMMAND[@]}"; do
    case "$t" in
      branch|diff|diff-index|format-patch|grep|log|reflog|rev-list|shortlog|show)
        color_arg="--color=$cmode"; break;;
    esac
  done
fi

# Walk the tree: find directories that contain .git, print them NUL-delimited,
# and prune so we never descend into a repo (matches gitall's skip_current_dir).
find_repos() {
  local fargs=()
  [ "$follow" -eq 1 ] && fargs+=( -L )
  fargs+=( "$directory" )
  [ -n "$max_depth" ] && fargs+=( -maxdepth "$max_depth" )
  fargs+=( -type d -exec test -d '{}/.git' ';' -prune -print0 )
  find "${fargs[@]}" 2>/dev/null
}

# Collect repos, applying the name / full-path regex filter.
repos=()
while IFS= read -r -d '' d; do
  if [ "$full_path" -eq 1 ]; then
    target=$(cd "$d" 2>/dev/null && pwd -P) || target=$d
  else
    target=${d##*/}
  fi
  if printf '%s' "$target" | grep -Eq -- "$regex"; then
    repos+=( "$d" )
  fi
done < <(find_repos)

[ ${#repos[@]} -eq 0 ] && exit 0

# Resolve our own path so the worker re-invocation works even when called by a
# bare name found on PATH.
self=$0
case "$self" in
  */*) : ;;
  *)   self=$(command -v -- "$self" 2>/dev/null || printf '%s' "$self");;
esac

tmpbase=$(mktemp -d "${TMPDIR:-/tmp}/gitall.XXXXXX")
trap 'rm -rf "$tmpbase"' EXIT
export GA_EXEC="$executable"
export GA_COLOR_ARG="$color_arg"
export GA_HEADER_COLOR="$header_color"
export GA_LOCKDIR="$tmpbase/lock"

printf '%s\0' "${repos[@]}" \
  | xargs -0 -P "$threads" -n1 "$self" --__gitall_worker "${COMMAND[@]}"
