# sourced (needs $here): load settings from config.toml into HERDR_NOTES_* unless already set in the environment
command -v python3 >/dev/null 2>&1 && eval "$(python3 "$here/config.py")"
