#!/usr/bin/env python3
"""Print shell assignments for settings in <plugin config dir>/config.toml. Environment variables win.

    width = 0.33            # notes pane width as a fraction of the tab (0 < w < 1)
    editor = "vim"
    key = "prefix+shift+n"  # used by `setup`
    notes_dir = "~/notes"   # fallback dir when there is no Claude session, and tab memory
    new_session = "blank"   # "blank" | "carry": what a new Claude session in the same tab starts with
    preview_key = "prefix+n"  # used by `setup`; no preview key is bound unless set
    viewer = "glow"         # preview renderer; without glow it falls back to the editor, read-only
"""
import os, re, shlex, sys

MAP = {"width": "HERDR_NOTES_WIDTH", "editor": "HERDR_NOTES_EDITOR", "key": "HERDR_NOTES_KEY",
       "notes_dir": "HERDR_NOTES_DIR", "new_session": "HERDR_NOTES_NEW_SESSION",
       "preview_key": "HERDR_NOTES_PREVIEW_KEY", "viewer": "HERDR_NOTES_VIEWER"}
d = os.environ.get("HERDR_PLUGIN_CONFIG_DIR") or os.path.expanduser("~/.config/herdr/plugins/config/ronzyfonzy.herdr-notes")
path = os.path.join(d, "config.toml")
try:
    raw = open(path, encoding="utf-8").read()
except OSError:
    sys.exit(0)
try:
    import tomllib
    cfg = tomllib.loads(raw)
except ImportError:  # python < 3.11: flat `key = "str"` / `key = number` only
    cfg = {}
    for line in raw.splitlines():
        m = re.match(r'\s*(\w+)\s*=\s*(?:"([^"]*)"|([\d.]+))\s*(#.*)?$', line)
        if m:
            cfg[m[1]] = m[2] if m[2] is not None else float(m[3])
except Exception as e:
    print(f"herdr-notes: cannot parse {path}: {e}", file=sys.stderr)
    sys.exit(0)

for k, var in MAP.items():
    if k not in cfg or os.environ.get(var):
        continue
    v = cfg[k]
    ok = {"width": isinstance(v, (int, float)) and not isinstance(v, bool) and 0 < v < 1,
          "new_session": v in ("blank", "carry")}.get(k, isinstance(v, str) and v != "")
    if not ok:
        print(f"herdr-notes: ignoring {k} = {v!r} in {path}", file=sys.stderr)
        continue
    if k == "notes_dir":
        v = os.path.expanduser(v)
    print(f"{var}={shlex.quote(str(v))}; export {var}")
