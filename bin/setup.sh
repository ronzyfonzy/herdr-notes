#!/bin/sh
# setup.sh install|uninstall — manage the keybinding block in config.toml and ~/.local/bin/herdr-notes-path.
# Never overwrites an occupied key; backs up config.toml before the first write.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/need.sh"; need python3
. "$here/config.sh"
export HERDR_PLUGIN_ROOT="${HERDR_PLUGIN_ROOT:-$(dirname "$here")}"
exec python3 - "$@" <<'PY'
import os, re, shutil, subprocess, sys

mode = sys.argv[1]
HERDR = os.environ.get("HERDR_BIN_PATH") or "herdr"
pid = os.environ.get("HERDR_PLUGIN_ID", "ronzyfonzy.herdr-notes")
root = os.environ["HERDR_PLUGIN_ROOT"]
cfg = os.environ.get("HERDR_NOTES_CONFIG") or os.path.expanduser("~/.config/herdr/config.toml")
key = os.environ.get("HERDR_NOTES_KEY", "prefix+shift+n")
bindir = os.path.expanduser("~/.local/bin")
notes_sh = os.path.join(root, "bin", "notes.sh")
MARK = "# managed by ronzyfonzy.herdr-notes setup"
wrappers = {"herdr-notes": f'exec sh "{notes_sh}" "$@"', "herdr-notes-path": f'exec sh "{notes_sh}" path'}
skill_link = os.path.expanduser("~/.claude/skills/herdr-notes")
skill_src = os.path.join(root, "skills", "notes")
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
    os.makedirs(bindir, exist_ok=True)
    for name, body in wrappers.items():
        w = os.path.join(bindir, name)
        ours = (os.path.islink(w) and os.readlink(w).endswith("bin/notes-path.sh")) or (os.path.isfile(w) and MARK in open(w).read())
        if os.path.exists(w) or os.path.islink(w):
            if not ours:
                msgs.append(f"{w} exists and is not ours; left untouched")
                continue
            os.remove(w)
        open(w, "w").write(f"#!/bin/sh\n{MARK}\n{body}\n")
        os.chmod(w, 0o755)
        msgs.append(f"installed {w}")
    os.makedirs(os.path.dirname(skill_link), exist_ok=True)
    if os.path.islink(skill_link) and (os.readlink(skill_link).endswith("skills/notes") or not os.path.exists(skill_link)):
        os.remove(skill_link)  # ours from an earlier install path, or dangling
    if os.path.exists(skill_link):
        msgs.append(f"{skill_link} exists and is not ours; left untouched")
    else:
        os.symlink(skill_src, skill_link)
        msgs.append(f"linked skill {skill_link}")
else:
    if rest != text:
        open(cfg, "w").write(rest)
        msgs.append(f"removed keybinding block from {cfg}")
    for name in wrappers:
        w = os.path.join(bindir, name)
        if os.path.isfile(w) and MARK in open(w).read():
            os.remove(w)
            msgs.append(f"removed {w}")
    if os.path.islink(skill_link) and os.readlink(skill_link) == skill_src:
        os.remove(skill_link)
        msgs.append(f"removed {skill_link}")

subprocess.run([HERDR, "server", "reload-config"], capture_output=True)
out = "; ".join(msgs) or "nothing to do"
print(out)
subprocess.run([HERDR, "notification", "show", f"herdr-notes {mode}", "--body", out], capture_output=True)
PY
