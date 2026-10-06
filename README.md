# herdr-notes

Your own Markdown notes in a side pane, one note per Claude Code session, next to the session in
[herdr](https://herdr.dev). Press a hotkey and a pane opens at a third of the tab width with your notes in
vim. Claude can read and edit the same file.

## Install

```bash
herdr plugin install ronzyfonzy/herdr-notes
herdr plugin action invoke setup --plugin ronzyfonzy.herdr-notes
```

`setup`:
- binds `prefix+shift+n` to the toggle (never overwriting an occupied key; `config.toml` is backed up once
  to `config.toml.herdr-notes-backup`), and the preview toggle too if `preview_key` is set (see Configuration),
- installs the `herdr-notes` and `herdr-notes-path` commands in `~/.local/bin`,
- links the Claude Code skill at `~/.claude/skills/herdr-notes`.

`uninstall` reverses all three. Run `setup` again after updating the plugin (the install path changes).

Requires `python3` and an editor (`vim` by default). `glow` is optional (preview only). macOS and Linux.

## Use

- `prefix+shift+n`: open the notes pane for the current tab, docked on the right. If it is open but not
  focused, the key focuses it; if it is focused, the key closes it (unsaved keystrokes are written first).
- vi-family editors reload when an agent edits the file (checked about once a second) and autosave while you
  type (after 2 seconds idle or on change). Markdown syntax highlighting and conceal are on.
- Preview (opt-in): set `preview_key` and run `setup`; that key toggles a read-only rendered view of the same
  note in its own pane (open / focus / close, like the notes pane). It uses [glow](https://github.com/charmbracelet/glow)
  and redraws within a second when the file changes. Without glow it opens the editor read-only instead.
  Output taller than the pane scrolls off the top; use the pane's scrollback.

### Agents

The shipped skill tells Claude how to use the notes; mention "my notes" and it will. The commands work from
Claude's own pane (they find the notes through its herdr tab):

```bash
herdr-notes read               # print the notes
herdr-notes append "text"      # append a line (also: echo text | herdr-notes append -)
herdr-notes path               # file path (alias: herdr-notes-path)
```

Prefer `append` to rewriting the file: you may have it open in vim. Don't use
`herdr plugin action invoke path` for this; actions resolve against the *focused* workspace, not the caller's.

## Where notes live

`~/.claude/projects/<project>/<session-id>.notes.md`, beside the session transcript (`<session-id>.jsonl`).
The session is found through herdr's `agent_session` for the Claude pane in the tab.

- By default a new Claude session in the same tab (`/clear`, fresh `claude`) starts with empty notes;
  `--resume` keeps them. Set `new_session = "carry"` to start the new session with a copy of the tab's
  previous note. The tab is remembered only while herdr runs, and only within the same project directory.
- No Claude session (or no transcript yet): `~/.local/state/herdr/notes/<workspace>.<tab-id>.md`.
  That file does not move into the session directory later.
- Claude Code's automatic cleanup deletes the transcript paths it lists (`<session>.jsonl`, subagent and
  tool-result directories, ...) after `cleanupPeriodDays` (default 30), not other files, so `*.notes.md`
  survives; it simply becomes an orphan once its transcript is gone. See Anthropic's
  [`.claude` directory docs](https://code.claude.com/docs/en/claude-directory).
- Claude Code only. Notes are plain, unencrypted text. Don't put secrets in them.

## Configuration

Optional `config.toml` in the plugin's config dir (`herdr plugin config-dir ronzyfonzy.herdr-notes`), read on
every use, no herdr restart needed:

```toml
width = 0.33             # notes pane width as a fraction of the tab (0 < width < 1)
editor = "vim"           # default: $EDITOR, then vim; auto-reload/autosave only for vim/vi/nvim
key = "prefix+shift+n"   # used by `setup`
notes_dir = "~/notes"    # fallback dir without a Claude session, and the tab memory for carry-over
new_session = "blank"    # "blank" or "carry"
preview_key = "prefix+n"  # used by `setup`; no preview key is bound unless set
viewer = "glow"          # preview renderer; if glow is missing, or set to another command, that runs read-only
```

Each setting can also be set with an environment variable, which wins over the file:
`HERDR_NOTES_WIDTH`, `HERDR_NOTES_EDITOR`, `HERDR_NOTES_KEY`, `HERDR_NOTES_DIR`, `HERDR_NOTES_NEW_SESSION`, `HERDR_NOTES_PREVIEW_KEY`, `HERDR_NOTES_VIEWER`.
An invalid value is ignored with a message in the plugin log.

## Development

```bash
herdr plugin link /path/to/herdr-notes
sh test/run.sh      # stubs `herdr` in a throwaway HOME; no running herdr needed
```

Tested on herdr 0.9.1. Pane `width` in the manifest is popup-only in herdr, so the width is set with
`pane split --ratio` (the ratio is the original pane's share).

## License

MIT
