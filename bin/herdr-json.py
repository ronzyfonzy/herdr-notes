#!/usr/bin/env python3
"""Tiny JSON helpers for toggle.sh. Reads a herdr CLI response on stdin.
  status LABEL      pane get    -> focused | unfocused | stale (missing pane or label mismatch)
  newpane           pane split  -> new pane id
  target CALLER     pane layout -> pane to split so the new pane docks on the tab's right edge
"""
import json, sys

mode = sys.argv[1]
try:
    d = json.load(sys.stdin).get("result", {})
except Exception:
    d = {}

if mode == "status":
    p = d.get("pane", {})
    print("stale" if p.get("label") != sys.argv[2] else "focused" if p.get("focused") else "unfocused")
elif mode == "newpane":
    print((d.get("pane") or {}).get("pane_id", ""))
elif mode == "target":
    panes = d.get("layout", {}).get("panes", [])
    if panes:
        right = lambda p: p["rect"]["x"] + p["rect"]["width"]
        edge = max(map(right, panes))
        # ponytail: with a stacked right column this docks beside the caller or the tallest pane there, not the whole column
        col = [p for p in panes if right(p) == edge]
        pick = [p for p in col if p["pane_id"] == sys.argv[2]] or sorted(col, key=lambda p: -p["rect"]["height"])
        print(pick[0]["pane_id"])
