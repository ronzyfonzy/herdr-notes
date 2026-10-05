#!/bin/sh
# Editor on the notes file. HERDR_NOTES_EDITOR > $EDITOR > vim.
# vi-family: autosave (2s idle / on change) and reload when an agent edits the file.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/config.sh"
. "$here/editor.sh"
f=${HERDR_NOTES_FILE:-$(sh "$here/notes-path.sh")} || { printf 'press enter\n'; read _; exit 1; }
if ! command -v "${ed%% *}" >/dev/null 2>&1; then
  printf "herdr-notes: editor '%s' not found. Set HERDR_NOTES_EDITOR.\nNotes file: %s\npress enter\n" "$ed" "$f"; read _; exit 1
fi
if [ "$is_vi" = 1 ]; then
  exec $ed --cmd 'filetype plugin indent on' --cmd 'syntax on' \
    -c 'set autoread autowriteall wrap linebreak updatetime=2000 conceallevel=2' \
    -c 'autocmd FocusGained,BufEnter * silent! checktime' \
    -c 'autocmd TextChanged,TextChangedI,CursorHoldI * silent! update' \
    -c 'if has("timers") | call timer_start(1000, {-> execute("silent! checktime")}, {"repeat": -1}) | endif' "$f"
fi
exec $ed "$f"
