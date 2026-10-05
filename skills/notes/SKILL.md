---
name: herdr-notes
description: Read or append to the user's own side-pane notes for the current herdr tab (the notes beside this Claude Code session). Use when the user mentions "my notes", asks you to note something down, or refers to ticket context they wrote down.
---

# herdr notes

The user keeps personal Markdown notes in a herdr side pane, one file per Claude session. You share the file.

```bash
herdr-notes read                 # print the notes
herdr-notes append "text"        # add a line at the end (also: echo text | herdr-notes append -)
herdr-notes path                 # file path, if you need to edit it
```

- Read the notes when the user mentions them or refers to context they wrote down.
- **Append, don't rewrite.** The user may have the file open in vim, which autosaves; rewriting the whole file races with their typing. For a targeted edit, change only the lines asked for.
- Only edit when asked. Never delete the user's notes.
- Run these commands from your own pane: they find the notes through your herdr tab. Outside herdr they fail.
