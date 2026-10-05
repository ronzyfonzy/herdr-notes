# herdr-notes

Your own Markdown notes in a side pane, one note per tab, next to a [Claude Code](https://claude.com/claude-code)
session in [herdr](https://herdr.dev). Press a hotkey, a pane opens at 1/3 width with your notes in vim.
Claude can read and edit the same file.

## Install

```bash
herdr plugin install ronzyfonzy/herdr-notes
herdr plugin action invoke setup --plugin ronzyfonzy.herdr-notes
```

`setup` binds `prefix+shift+n` to the toggle (never overwriting an occupied key, backing up `config.toml`
once to `config.toml.herdr-notes-backup`) and links `~/.local/bin/herdr-notes-path`.
`uninstall` reverses both.

Requires `python3` and an editor (`vim` by default). macOS and Linux.

## Use

- `prefix+shift+n`: open the notes pane for the current tab; press again to close it.
- Tell Claude "read my notes". Claude runs `herdr-notes-path` from its own pane, which prints the file for its tab.
  Put this in `~/.claude/CLAUDE.md` so every session knows:

  ```
  ## Personal notes
  "My notes" = my herdr side-pane notes for this session. Get the file path with
  `herdr-notes-path`. Read it when I mention my notes or the ticket context.
  Edit only when I ask, with appends or targeted edits; I may have it open in vim.
  ```

  Use `herdr-notes-path` rather than `herdr plugin action invoke path`: the action resolves against
  whichever workspace is *focused*, not the caller's.
- vi-family editors reload automatically when an agent edits the file (checked about once a second).

## Where notes live

`~/.claude/projects/<project>/<session-id>.notes.md`, beside the session transcript (`<session-id>.jsonl`).
The session is found through herdr's `agent_session` for the Claude pane in the tab.

- A new Claude session in the same tab (`/clear`, fresh `claude`) starts with empty notes; `--resume` keeps them.
- No Claude session (or no transcript yet): `~/.local/state/herdr/notes/<workspace>.<tab-id>.md`.
  That file does not move into the session directory later.
- Claude Code only. Whether Claude Code's own cleanup of old sessions also removes `*.notes.md` is untested.
- Notes are plain, unencrypted text. Don't put secrets in them.

## Configuration

Environment variables, set where the herdr server starts (restart the server after changing them):

| Variable | Default | Meaning |
|---|---|---|
| `HERDR_NOTES_WIDTH` | `0.33` | Pane width as a fraction of the tab |
| `HERDR_NOTES_EDITOR` | `$EDITOR`, then `vim` | Editor command; auto-reload only for vim/vi/nvim |
| `HERDR_NOTES_DIR` | `~/.local/state/herdr/notes` | Fallback directory when there is no Claude session |
| `HERDR_NOTES_KEY` | `prefix+shift+n` | Key used by `setup` |

## Development

```bash
herdr plugin link /path/to/herdr-notes
sh test/run.sh      # stubs `herdr` in a throwaway HOME; no running herdr needed
```

Tested on herdr 0.9.1.

## License

MIT
