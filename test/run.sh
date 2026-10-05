#!/bin/sh
# Runs notes-path.sh and setup.sh against a stubbed `herdr` in a throwaway HOME. Exit 0 = all pass.
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home" HERDR_PLUGIN_ROOT="$root" HERDR_PLUGIN_ID=test.herdr-notes
mkdir -p "$tmp/bin" "$HOME/.claude/projects/proj" "$HOME/.config/herdr"
touch "$HOME/.claude/projects/proj/S1.jsonl" "$HOME/.claude/projects/proj/S2.jsonl"

cat > "$tmp/bin/herdr" <<'STUB'
#!/bin/sh
case "$1 $2" in
  "workspace get") echo '{"result":{"workspace":{"label":"proj"}}}' ;;
  "tab get")       echo '{"result":{"tab":{"label":"mytab"}}}' ;;
  "pane list")     echo '{"result":{"panes":[
    {"pane_id":"w1:p1","tab_id":"w1:t1","agent":"claude","agent_session":{"value":"S1"}},
    {"pane_id":"w1:p2","tab_id":"w1:t2","agent":"claude","agent_session":{"value":"S2"}},
    {"pane_id":"w1:p3","tab_id":"w1:t3"}]}}' ;;
  *) echo '{}' ;;
esac
STUB
chmod +x "$tmp/bin/herdr"; export PATH="$tmp/bin:$PATH"
export HERDR_WORKSPACE_ID=w1

fail=0
check() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1"; echo "  want $2"; echo "  got  $3"; fail=1; fi
}
P=$HOME/.claude/projects/proj
check "caller pane hosts claude"  "$P/S1.notes.md" "$(HERDR_PANE_ID=w1:p1 HERDR_TAB_ID=w1:t1 sh "$root/bin/notes-path.sh")"
check "falls back to tab's claude" "$P/S2.notes.md" "$(HERDR_PANE_ID= HERDR_TAB_ID=w1:t2 sh "$root/bin/notes-path.sh")"
check "no agent -> state dir"      "$HOME/.local/state/herdr/notes/proj.w1-t3.md" "$(HERDR_PANE_ID=w1:p3 HERDR_TAB_ID=w1:t3 sh "$root/bin/notes-path.sh")"
check "header written"             "# proj / mytab" "$(head -1 "$P/S1.notes.md")"

cfg=$HOME/.config/herdr/config.toml
sh "$root/bin/setup.sh" install >/dev/null; sh "$root/bin/setup.sh" install >/dev/null
check "setup idempotent (1 block)" 1 "$(grep -c '^# BEGIN test.herdr-notes' "$cfg")"
check "cli symlink"                "$root/bin/notes-path.sh" "$(readlink "$HOME/.local/bin/herdr-notes-path")"
sh "$root/bin/setup.sh" uninstall >/dev/null
check "uninstall removes block"    0 "$(grep -c 'herdr-notes' "$cfg")"
check "uninstall removes symlink"  no "$([ -e "$HOME/.local/bin/herdr-notes-path" ] && echo yes || echo no)"
printf '[[keys.command]]\nkey = "prefix+shift+n"\ntype = "x"\n' > "$cfg"
sh "$root/bin/setup.sh" install >/dev/null
check "occupied key not overwritten" 0 "$(grep -c 'herdr-notes' "$cfg")"
exit $fail
