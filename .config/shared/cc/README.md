# Claude Code

Shared Claude Code helpers.

## Statusline

`statusline.sh` is installed by the root `install.sh` when both `claude` and
`jq` are available. The installer copies it to `~/.config/cc/statusline.sh`,
marks the installed copy executable, and writes this entry to
`~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/home/you/.config/cc/statusline.sh"
  }
}
```

The script reads Claude Code statusline JSON from stdin and renders ANSI
segments for model, effort, compact-window progress modulo total context,
current directory, Git branch, and dirty state. It falls back gracefully when
optional fields are missing.
