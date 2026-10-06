#!/bin/sh
# toggle.sh [preview] — toggle this tab's notes pane (or, with `preview`, its rendered preview pane): open (docked right) / focus if open elsewhere / close if focused.
# A stored pane only counts if herdr still reports it with our label, so a stale id is never closed or focused.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/need.sh"; need python3
. "$here/config.sh"
. "$here/editor.sh"
mode=notes; label=notes; sfx=
[ "${1:-}" = preview ] && { mode=preview; label=notes-preview; sfx=-preview; is_vi=0; }
dir=${HERDR_PLUGIN_STATE_DIR:-$HOME/.local/state/herdr/notes}
tab=$(printf %s "$HERDR_TAB_ID" | tr -c 'A-Za-z0-9\n' _)
state="$dir/.pane-$tab$sfx"; lock="$dir/.lock-$tab"
mkdir -p "$dir"

# serialize presses; a lock older than 10s is taken over
if ! mkdir "$lock" 2>/dev/null; then
  [ $(( $(date +%s) - $(cat "$lock/t" 2>/dev/null || echo 0) )) -gt 10 ] || exit 0
  rm -rf "$lock"; mkdir "$lock" 2>/dev/null || exit 0
fi
trap 'rm -rf "$lock"' EXIT
date +%s > "$lock/t"

focus() { herdr pane zoom "$1" --on >/dev/null 2>&1; herdr pane zoom "$1" --off >/dev/null 2>&1; }
close_pane() {
  if [ "$is_vi" = 1 ]; then # let vim write unsaved keystrokes first
    herdr pane send-keys "$1" Escape >/dev/null 2>&1
    herdr pane send-text "$1" ':silent! update' >/dev/null 2>&1
    herdr pane send-keys "$1" Enter >/dev/null 2>&1
    sleep 0.3
  fi
  herdr pane close "$1" >/dev/null 2>&1
}

status=stale
if [ -s "$state" ]; then
  id=$(cat "$state")
  status=$(herdr pane get "$id" 2>/dev/null | python3 "$here/herdr-json.py" status "$label")
fi
case $status in
  focused)   rm -f "$state"; close_pane "$id"; exit 0 ;;
  unfocused) focus "$id"; exit 0 ;;
esac
rm -f "$state"

f=$(sh "$here/notes-path.sh") || exit 1
target=$(herdr pane layout ${HERDR_PANE_ID:+--pane "$HERDR_PANE_ID"} 2>/dev/null | python3 "$here/herdr-json.py" target "${HERDR_PANE_ID:-}")
if [ -z "$target" ]; then # layout unavailable: declarative pane, 50/50
  herdr plugin pane open --plugin "${HERDR_PLUGIN_ID:-ronzyfonzy.herdr-notes}" --entrypoint notes \
    --placement split --direction right --cwd "${PWD:-$HOME}" --env "HERDR_NOTES_FILE=$f" --env "HERDR_NOTES_MODE=$mode" --focus
  exit
fi
# --ratio is the original pane's share, so 1 - width leaves the notes pane `width` of the tab
ratio=$(LC_ALL=C awk -v w="${HERDR_NOTES_WIDTH:-0.33}" 'BEGIN{printf "%.2f", 1-w}')
np=$(herdr pane split "$target" --direction right --ratio "$ratio" --cwd "${PWD:-$HOME}" \
  --env "HERDR_NOTES_FILE=$f" --env "HERDR_NOTES_MODE=$mode" --env "HERDR_NOTES_ROOT=$(dirname "$here")" --no-focus 2>/dev/null \
  | python3 "$here/herdr-json.py" newpane)
[ -n "$np" ] || exit 1
printf '%s' "$np" > "$state"
herdr pane rename "$np" "$label" >/dev/null 2>&1
herdr pane run "$np" 'exec sh "$HERDR_NOTES_ROOT/bin/notes-pane.sh"' >/dev/null 2>&1
focus "$np"
