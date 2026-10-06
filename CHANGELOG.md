# Changelog

## 0.4.0
- `preview` action: a read-only rendered view of the tab's note in its own pane, toggled like the notes pane. Rendered with glow, redrawn when the file changes; falls back to the editor (read-only) when glow is not installed.
- `preview_key` binds it via `setup` (opt-in, never overwrites an occupied key); `viewer` picks the renderer.

## 0.3.0
- `herdr-notes read | append | path` commands for agents; `herdr-notes-path` kept as an alias. `setup` now installs them as small wrapper scripts, so they keep working across plugin updates once `setup` is re-run.
- Claude Code skill (`skills/notes`) linked by `setup`, replacing the manual CLAUDE.md snippet.
- `config.toml` in the plugin config dir (width, editor, key, notes_dir, new_session); environment variables still override.
- `new_session = "carry"` starts a new Claude session in the same tab with a copy of the tab's previous note (default `blank`).
- Documented that Claude Code's cleanup does not delete `*.notes.md`.

## 0.2.0
- Toggle is now open / focus / close: pressing it while the notes pane is open but unfocused focuses it; pressing it while focused closes it.
- The notes pane is identified by label, so a stale or reused pane id is never closed or focused.
- Fast double presses no longer open two panes (per-tab lock).
- Docks on the tab's right edge in one step (`pane split --ratio`), no 50/50 flash.
- Closing saves unsaved keystrokes first; vim autosaves while you type and has markdown syntax/conceal on.
- CI (ubuntu + macOS) and toggle tests.

## 0.1.2
- Call herdr through `HERDR_BIN_PATH` when set.
- Keep open-pane tracking files in `HERDR_PLUGIN_STATE_DIR`.

## 0.1.1
- Open the notes pane next to the caller's own pane, not in whichever workspace is focused.
- Reload the file in vim every second so edits by agents show up while the pane is unfocused.

## 0.1.0
- Toggle a 1/3-width notes pane per tab (`prefix+shift+n` via `setup`).
- Notes stored next to the Claude Code session transcript; state-dir fallback.
- `herdr-notes-path` command for agents; `setup` / `uninstall` actions.
