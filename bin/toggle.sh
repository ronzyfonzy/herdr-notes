#!/bin/sh
# Close this tab's notes pane if open, else open it as a right split.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/need.sh"; need python3
state="${HERDR_PLUGIN_STATE_DIR:-$HOME/.local/state/herdr/notes}/.pane-$(printf %s "$HERDR_TAB_ID" | tr -c 'A-Za-z0-9\n' _)"
mkdir -p "$(dirname "$state")"
if [ -s "$state" ]; then
  id=$(cat "$state"); rm -f "$state"
  if herdr pane get "$id" >/dev/null 2>&1; then herdr pane close "$id"; exit; fi
fi
f=$(sh "$here/notes-path.sh") || exit 1
# target the caller's own pane, not whichever workspace happens to be focused
out=$(herdr plugin pane open --plugin "${HERDR_PLUGIN_ID:-ronzyfonzy.herdr-notes}" --entrypoint notes \
  ${HERDR_PANE_ID:+--target-pane "$HERDR_PANE_ID"} \
  --placement split --direction right --cwd "${PWD:-$HOME}" --env "HERDR_NOTES_FILE=$f" --focus) || exit 1
printf '%s' "$out" | grep -o '"pane_id":"[^"]*"' | head -1 | cut -d'"' -f4 > "$state"
# a fresh split is 50/50; shrink the notes pane to HERDR_NOTES_WIDTH (fraction of the tab, default 1/3)
pane=$(cat "$state")
[ -n "$pane" ] && herdr pane resize --pane "$pane" --direction right \
  --amount "$(LC_ALL=C awk -v w="${HERDR_NOTES_WIDTH:-0.33}" 'BEGIN{print 0.5-w}')" >/dev/null 2>&1
exit 0
