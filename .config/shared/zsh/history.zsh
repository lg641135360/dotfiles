#######################################################
# History Configuration
#######################################################

# HISTFILE 跟随 ZDOTDIR，集中所有 zsh 状态文件到 ~/.config/zsh/。
# 旧 live 环境的 ~/.zsh_history 需手动 mv 到 $ZDOTDIR/.zsh_history。
HISTSIZE=10000
HISTFILE=$ZDOTDIR/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups     # includes hist_ignore_dups behavior
setopt hist_save_no_dups
setopt hist_find_no_dups

# History search with arrow keys (formerly keybindings.zsh)
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward
