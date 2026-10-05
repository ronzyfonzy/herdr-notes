# sourced: herdr() calls the running binary (HERDR_BIN_PATH); need <cmd> — fail loudly (log, stderr, and an on-screen notification) if cmd is missing
herdr() { "${HERDR_BIN_PATH:-herdr}" "$@"; }
need() {
  command -v "$1" >/dev/null 2>&1 && return 0
  echo "herdr-notes: '$1' not found in PATH" >&2
  herdr notification show "herdr-notes: $1 not found" --body "Install $1 to use the notes plugin." >/dev/null 2>&1
  exit 1
}
