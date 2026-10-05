#!/bin/sh
# setup.sh install|uninstall — manage the keybinding block in config.toml and ~/.local/bin/herdr-notes-path.
# Never overwrites an occupied key; backs up config.toml before the first write.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/need.sh"; need python3
export HERDR_PLUGIN_ROOT="${HERDR_PLUGIN_ROOT:-$(dirname "$here")}"
exec python3 - "$@" <<'PY'
import os, re, shutil, subprocess, sys

mode = sys.argv[1]
pid = os.environ.get("HERDR_PLUGIN_ID", "ronzyfonzy.herdr-notes")
root = os.environ["HERDR_PLUGIN_ROOT"]
cfg = os.environ.get("HERDR_NOTES_CONFIG") or os.path.expanduser("~/.config/herdr/config.toml")
key = os.environ.get("HERDR_NOTES_KEY", "prefix+shift+n")
link = os.path.expanduser("~/.local/bin/herdr-notes-path")
target = os.path.join(root, "bin", "notes-path.sh")
msgs = []

text = open(cfg).read() if os.path.exists(cfg) else ""
block = re.compile(rf"\n?# BEGIN {re.escape(pid)}[^\n]*\n.*?# END {re.escape(pid)}\n", re.S)
rest = block.sub("", text)

if mode == "install":
    occupied = any(re.search(rf"""["']{re.escape(key)}["']""", l)
                   for l in rest.splitlines() if not l.lstrip().startswith("#"))
    if occupied:
        msgs.append(f"key {key} is already bound in {cfg}; left untouched (set HERDR_NOTES_KEY to another key)")
    else:
        if text and not os.path.exists(cfg + ".herdr-notes-backup"):
            shutil.copy(cfg, cfg + ".herdr-notes-backup")
        new = rest.rstrip("\n") + f'''

# BEGIN {pid} — managed by `setup`; edit via the plugin, not by hand
[[keys.command]]
key = "{key}"
type = "plugin_action"
command = "{pid}.toggle"
description = "notes: toggle side pane"
# END {pid}
'''
        os.makedirs(os.path.dirname(cfg), exist_ok=True)
        open(cfg, "w").write(new)
        msgs.append(f"bound {key} -> {pid}.toggle")
    os.makedirs(os.path.dirname(link), exist_ok=True)
    if os.path.islink(link) or not os.path.exists(link):
        if os.path.islink(link):
            os.remove(link)
        os.symlink(target, link)
        msgs.append(f"linked {link}")
    else:
        msgs.append(f"{link} exists and is not a symlink; left untouched")
else:
    if rest != text:
        open(cfg, "w").write(rest)
        msgs.append(f"removed keybinding block from {cfg}")
    if os.path.islink(link) and os.readlink(link) == target:
        os.remove(link)
        msgs.append(f"removed {link}")

subprocess.run(["herdr", "server", "reload-config"], capture_output=True)
out = "; ".join(msgs) or "nothing to do"
print(out)
subprocess.run(["herdr", "notification", "show", f"herdr-notes {mode}", "--body", out], capture_output=True)
PY
