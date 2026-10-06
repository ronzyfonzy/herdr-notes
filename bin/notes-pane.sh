#!/bin/sh
# Editor on the notes file. HERDR_NOTES_EDITOR > $EDITOR > vim.
# vi-family: autosave (2s idle / on change) and reload when an agent edits the file.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/config.sh"
preview=0; [ "${HERDR_NOTES_MODE:-}" = preview ] && preview=1
v=${HERDR_NOTES_VIEWER:-glow}
[ "$preview" = 1 ] && [ "$v" != glow ] && HERDR_NOTES_EDITOR=$v
. "$here/editor.sh"
f=${HERDR_NOTES_FILE:-$(sh "$here/notes-path.sh")} || { printf 'press enter\n'; read _; exit 1; }
if [ "$preview" = 1 ] && [ "$v" = glow ] && command -v glow >/dev/null 2>&1; then
  # read-only rendered view; redraw when the file or the pane size changes
  # ponytail: output taller than the pane scrolls off the top; no pager, so live reload stays simple
  last=
  while :; do
    cur=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)-$(tput cols)x$(tput lines)
    if [ "$cur" != "$last" ]; then
      last=$cur
      printf '\033[H\033[2J'
      glow -s "${GLOW_STYLE:-auto}" -w "$(tput cols)" "$f" 2>&1 | cat
    fi
    sleep 1
  done
fi
if ! command -v "${ed%% *}" >/dev/null 2>&1; then
  printf "herdr-notes: editor '%s' not found. Set HERDR_NOTES_EDITOR.\nNotes file: %s\npress enter\n" "$ed" "$f"; read _; exit 1
fi
if [ "$is_vi" = 1 ]; then
  set -- --cmd 'filetype plugin indent on' --cmd 'syntax on' \
    -c 'set autoread autowriteall wrap linebreak updatetime=2000 conceallevel=2' \
    -c 'autocmd FocusGained,BufEnter * silent! checktime' \
    -c 'if has("timers") | call timer_start(1000, {-> execute("silent! checktime")}, {"repeat": -1}) | endif'
  if [ "$preview" = 1 ]; then set -- -R "$@"; else set -- "$@" -c 'autocmd TextChanged,TextChangedI,CursorHoldI * silent! update'; fi
  exec $ed "$@" "$f"
fi
exec $ed "$f"
