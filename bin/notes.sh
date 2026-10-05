#!/bin/sh
# herdr-notes [path | read | append TEXT... | append -]   (append - reads stdin)
here=$(cd "$(dirname "$0")" && pwd)
file=$(sh "$here/notes-path.sh") || exit 1
case ${1:-path} in
  path) printf '%s\n' "$file" ;;
  read) cat "$file" ;;
  append)
    shift
    if [ $# -eq 0 ] || [ "$1" = - ]; then text=$(cat); else text="$*"; fi
    [ -n "$text" ] || { echo "herdr-notes: nothing to append" >&2; exit 1; }
    # ponytail: one O_APPEND write, no lock; fine for small appends, add flock if agents ever append concurrently in bulk
    pre=; [ -s "$file" ] && [ -n "$(tail -c1 "$file")" ] && pre='\n'
    printf "$pre%s\n" "$text" >> "$file" ;;
  *) echo "usage: herdr-notes [path|read|append TEXT...|append -]" >&2; exit 2 ;;
esac
