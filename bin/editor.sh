# sourced: ed = editor command, is_vi = 1 for vi-family editors (they get autosave/reload flags)
ed=${HERDR_NOTES_EDITOR:-${EDITOR:-vim}}
case $(basename "${ed%% *}") in vim|vi|nvim) is_vi=1 ;; *) is_vi=0 ;; esac
