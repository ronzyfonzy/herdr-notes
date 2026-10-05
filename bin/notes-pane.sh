#!/bin/sh
# Editor on the notes file. HERDR_NOTES_EDITOR > $EDITOR > vim. vi-family editors reload when agents edit the file.
f=${HERDR_NOTES_FILE:-$(sh "$HERDR_PLUGIN_ROOT/bin/notes-path.sh")} || { printf 'press enter\n'; read _; exit 1; }
ed=${HERDR_NOTES_EDITOR:-${EDITOR:-vim}}
if ! command -v "${ed%% *}" >/dev/null 2>&1; then
  printf "herdr-notes: editor '%s' not found. Set HERDR_NOTES_EDITOR.\nNotes file: %s\npress enter\n" "$ed" "$f"; read _; exit 1
fi
case $(basename "${ed%% *}") in
  vim|vi|nvim) exec $ed -c 'set autoread wrap linebreak' -c 'autocmd FocusGained,BufEnter * silent! checktime' -c 'if has("timers") | call timer_start(1000, {-> execute("silent! checktime")}, {"repeat": -1}) | endif' "$f" ;;
  *) exec $ed "$f" ;;
esac
