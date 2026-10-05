#!/bin/sh
# Runs notes-path.sh, toggle.sh and setup.sh against a stubbed `herdr` in a throwaway HOME. Exit 0 = all pass.
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
unset HERDR_PLUGIN_CONFIG_DIR HERDR_NOTES_DIR HERDR_NOTES_WIDTH HERDR_NOTES_NEW_SESSION HERDR_BIN_PATH HERDR_PLUGIN_STATE_DIR HERDR_PANE_ID HERDR_TAB_ID HERDR_NOTES_FILE HERDR_NOTES_EDITOR EDITOR
export HOME="$tmp/home" HERDR_PLUGIN_ROOT="$root" HERDR_PLUGIN_ID=test.herdr-notes STUB_LOG="$tmp/calls"
mkdir -p "$tmp/bin" "$HOME/.claude/projects/proj" "$HOME/.config/herdr"
touch "$HOME/.claude/projects/proj/S1.jsonl" "$HOME/.claude/projects/proj/S2.jsonl" "$HOME/.claude/projects/proj/S3.jsonl" "$HOME/.claude/projects/proj/S4.jsonl"

cat > "$tmp/bin/herdr" <<'STUB'
#!/bin/sh
echo "$*" >> "$STUB_LOG"
case "$1 $2" in
  "workspace get") echo '{"result":{"workspace":{"label":"proj"}}}' ;;
  "tab get")       echo '{"result":{"tab":{"label":"mytab"}}}' ;;
  "pane list")     echo '{"result":{"panes":[
    {"pane_id":"w1:p1","tab_id":"w1:t1","agent":"claude","agent_session":{"value":"'"${STUB_SID:-S1}"'"}},
    {"pane_id":"w1:p2","tab_id":"w1:t2","agent":"claude","agent_session":{"value":"S2"}},
    {"pane_id":"w1:p3","tab_id":"w1:t3"}]}}' ;;
  "pane get")      [ "${STUB_EXISTS:-1}" = 1 ] \
                     && echo "{\"result\":{\"pane\":{\"pane_id\":\"$3\",\"label\":\"${STUB_LABEL:-notes}\",\"focused\":${STUB_FOCUSED:-false}}}}" \
                     || echo '{"error":{"code":"pane_not_found"}}' ;;
  "pane layout")   echo '{"result":{"layout":{"panes":[
    {"pane_id":"w1:p1","rect":{"x":0,"width":117,"height":50}},
    {"pane_id":"w1:p9","rect":{"x":117,"width":117,"height":50}}]}}}' ;;
  "pane split")    echo '{"result":{"pane":{"pane_id":"w1:pNEW"}}}' ;;
  *) echo '{}' ;;
esac
STUB
chmod +x "$tmp/bin/herdr"; export PATH="$tmp/bin:$PATH"
export HERDR_WORKSPACE_ID=w1

fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1"; echo "  want $2"; echo "  got  $3"; fail=1; fi
}
called() { grep -qF -- "$1" "$STUB_LOG" && echo yes || echo no; }
P=$HOME/.claude/projects/proj
check "caller pane hosts claude"  "$P/S1.notes.md" "$(HERDR_PANE_ID=w1:p1 HERDR_TAB_ID=w1:t1 sh "$root/bin/notes-path.sh")"
check "falls back to tab's claude" "$P/S2.notes.md" "$(HERDR_PANE_ID= HERDR_TAB_ID=w1:t2 sh "$root/bin/notes-path.sh")"
check "no agent -> state dir"      "$HOME/.local/state/herdr/notes/proj.w1-t3.md" "$(HERDR_PANE_ID=w1:p3 HERDR_TAB_ID=w1:t3 sh "$root/bin/notes-path.sh")"
check "header written"             "# proj / mytab" "$(head -1 "$P/S1.notes.md")"

# notes.sh read/append
export HERDR_PANE_ID=w1:p1 HERDR_TAB_ID=w1:t1
sh "$root/bin/notes.sh" append "first line" ; sh "$root/bin/notes.sh" append second line
printf 'no newline at end' >> "$P/S1.notes.md"; echo piped | sh "$root/bin/notes.sh" append -
check "append: adds lines, fixes missing newline" "first line|second line|no newline at end|piped" "$(sed -n '3,$p' "$P/S1.notes.md" | paste -sd'|' -)"
check "read prints the file" "$(cat "$P/S1.notes.md")" "$(sh "$root/bin/notes.sh" read)"
check "path subcommand"      "$P/S1.notes.md" "$(sh "$root/bin/notes.sh" path)"

# new session in the same tab: blank by default, carry via config.toml
STUB_SID=S3 sh "$root/bin/notes-path.sh" >/dev/null
check "new session defaults to blank" "# proj / mytab" "$(head -1 "$P/S3.notes.md")$(sed -n 3p "$P/S3.notes.md")"
cd_="$HOME/.config/herdr/plugins/config/ronzyfonzy.herdr-notes"; mkdir -p "$cd_"
printf 'new_session = "carry"\nwidth = 0.25\n' > "$cd_/config.toml"
STUB_SID=S4 sh "$root/bin/notes-path.sh" >/dev/null
check "carry: copies previous session note (from S3)" "$(cat "$P/S3.notes.md")" "$(cat "$P/S4.notes.md")"
rm "$P/S4.notes.md"; HERDR_NOTES_NEW_SESSION=blank STUB_SID=S4 sh "$root/bin/notes-path.sh" >/dev/null
check "env overrides config (blank)" "# proj / mytab" "$(head -1 "$P/S4.notes.md")$(sed -n 3p "$P/S4.notes.md")"
unset HERDR_PANE_ID HERDR_TAB_ID

# toggle: OPEN / FOCUS / CLOSE / stale / lock
export HERDR_PLUGIN_STATE_DIR="$tmp/state" HERDR_TAB_ID=w1:t1 HERDR_PANE_ID=w1:p1
st=$HERDR_PLUGIN_STATE_DIR/.pane-w1_t1
toggle() { : > "$STUB_LOG"; sh "$root/bin/toggle.sh"; }
toggle
check "open: docks right of rightmost pane (config width 0.25)" yes "$(called 'pane split w1:p9 --direction right --ratio 0.75')"
check "open: labels the pane"      yes "$(called 'pane rename w1:pNEW notes')"
check "open: runs the editor"      yes "$(called 'pane run w1:pNEW')"
check "open: remembers the pane"   w1:pNEW "$(cat "$st")"
check "config.toml width 0.25 -> ratio 0.75" yes "$(called '--ratio 0.75')"
rm -f "$st"; HERDR_NOTES_WIDTH=0.4 toggle
check "env width beats config -> ratio 0.60" yes "$(called '--ratio 0.60')"
STUB_FOCUSED=false toggle
check "focus: unfocused -> zoom cycle" yes "$(called 'pane zoom w1:pNEW --on')"
check "focus: does not close/split"    no "$(called 'pane close')$(called 'pane split' | grep yes)"
STUB_FOCUSED=true toggle
check "close: focused -> closes"   yes "$(called 'pane close w1:pNEW')"
check "close: forgets the pane"    no "$([ -e "$st" ] && echo yes || echo no)"
echo w1:pOLD > "$st"; STUB_LABEL=other toggle
check "stale label: never closes foreign pane" no "$(called 'pane close w1:pOLD')"
check "stale label: opens a new one"           yes "$(called 'pane split')"
echo w1:pOLD > "$st"; STUB_EXISTS=0 toggle
check "missing pane: opens a new one"          yes "$(called 'pane split')"
mkdir "$HERDR_PLUGIN_STATE_DIR/.lock-w1_t1"; date +%s > "$HERDR_PLUGIN_STATE_DIR/.lock-w1_t1/t"; rm -f "$st"; toggle
check "lock held: second press is a no-op"     no "$(called 'pane split')"
rm -rf "$HERDR_PLUGIN_STATE_DIR/.lock-w1_t1"
unset HERDR_PLUGIN_STATE_DIR HERDR_TAB_ID HERDR_PANE_ID

cfg=$HOME/.config/herdr/config.toml
sh "$root/bin/setup.sh" install >/dev/null; sh "$root/bin/setup.sh" install >/dev/null
check "setup idempotent (1 block)" 1 "$(grep -c '^# BEGIN test.herdr-notes' "$cfg")"
check "herdr-notes wrapper"        yes "$(grep -q "$root/bin/notes.sh" "$HOME/.local/bin/herdr-notes" && [ -x "$HOME/.local/bin/herdr-notes" ] && echo yes || echo no)"
check "herdr-notes-path wrapper"   "$P/S1.notes.md" "$(HERDR_PANE_ID=w1:p1 HERDR_TAB_ID=w1:t1 "$HOME/.local/bin/herdr-notes-path")"
check "skill linked"               "$root/skills/notes" "$(readlink "$HOME/.claude/skills/herdr-notes")"
sh "$root/bin/setup.sh" uninstall >/dev/null
check "uninstall removes block"    0 "$(grep -c 'herdr-notes' "$cfg")"
check "uninstall removes wrappers" no "$([ -e "$HOME/.local/bin/herdr-notes" ] || [ -e "$HOME/.local/bin/herdr-notes-path" ] && echo yes || echo no)"
check "uninstall removes skill"    no "$([ -e "$HOME/.claude/skills/herdr-notes" ] && echo yes || echo no)"
printf '[[keys.command]]\nkey = "prefix+shift+n"\ntype = "x"\n' > "$cfg"
sh "$root/bin/setup.sh" install >/dev/null
check "occupied key not overwritten" 0 "$(grep -c 'herdr-notes' "$cfg")"
exit $fail
