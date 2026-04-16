#######################################################
# History Configuration
#######################################################

HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups     # includes hist_ignore_dups behavior
setopt hist_save_no_dups
setopt hist_find_no_dups
