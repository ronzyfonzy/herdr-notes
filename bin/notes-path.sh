#!/bin/sh
# Prints (and creates if missing) the notes file for the caller's tab.
# Preferred: <claude project dir>/<session-id>.notes.md, next to the session transcript.
# Fallback (no claude session/transcript yet): $HERDR_NOTES_DIR/<workspace>.<tab-id>.md.
here=$(cd "$(dirname "$0")" && pwd)
command -v python3 >/dev/null 2>&1 || { echo "herdr-notes: 'python3' not found in PATH" >&2; exit 1; }
. "$here/config.sh"
exec python3 - <<'PY'
import glob, json, os, re, shutil, subprocess

env = os.environ
ws_id, tab_id, pane_id = (env.get(k, "") for k in ("HERDR_WORKSPACE_ID", "HERDR_TAB_ID", "HERDR_PANE_ID"))

def herdr(*args):
    try:
        out = subprocess.run((env.get("HERDR_BIN_PATH") or "herdr",) + args, capture_output=True, text=True).stdout
        return json.loads(out)["result"]
    except Exception:
        return {}

ws = herdr("workspace", "get", ws_id).get("workspace", {}).get("label") or ws_id
tab = herdr("tab", "get", tab_id).get("tab", {}).get("label") or tab_id

# the caller's own pane if it hosts claude, else the first claude pane in the tab
claude = [p for p in herdr("pane", "list", "--workspace", ws_id).get("panes", [])
          if p.get("agent") == "claude" and (p.get("agent_session") or {}).get("value")]
claude = [p for p in claude if p["pane_id"] == pane_id] or [p for p in claude if p["tab_id"] == tab_id]
sid = claude[0]["agent_session"]["value"] if claude else ""
hit = glob.glob(os.path.expanduser(f"~/.claude/projects/*/{sid}.jsonl")) if sid else []

notes_dir = env.get("HERDR_NOTES_DIR") or os.path.expanduser("~/.local/state/herdr/notes")
if hit:
    f = hit[0][:-len(".jsonl")] + ".notes.md"
else:
    os.makedirs(notes_dir, exist_ok=True)
    f = os.path.join(notes_dir, re.sub(r"[^A-Za-z0-9._-]", "-", f"{ws}.{tab_id}") + ".md")

# per-tab memory of the last session note, only meaningful while herdr runs (tab ids are runtime handles)
mem = os.path.join(notes_dir, ".last-" + re.sub(r"[^A-Za-z0-9]", "_", tab_id)) if hit and tab_id else ""
if not os.path.exists(f):
    last = open(mem).read().strip() if mem and os.path.exists(mem) else ""
    # ponytail: same-project-dir check is the only guard against a reused tab id after a herdr restart
    if env.get("HERDR_NOTES_NEW_SESSION") == "carry" and last and last != f \
            and os.path.dirname(last) == os.path.dirname(f) and os.path.exists(last):
        shutil.copyfile(last, f)
    else:
        with open(f, "w") as fh:
            fh.write(f"# {ws} / {tab}\n\n")
if mem:
    os.makedirs(notes_dir, exist_ok=True)
    open(mem, "w").write(f)
print(f)
PY
