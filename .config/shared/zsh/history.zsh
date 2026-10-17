#######################################################
# History Configuration
#######################################################

# HISTFILE 跟随 ZDOTDIR，集中所有 zsh 状态文件到 ~/.config/zsh/。
# 旧 live 环境的 ~/.zsh_history 需手动 mv 到 $ZDOTDIR/.zsh_history。
# 注：zsh 没有 HISTDUP 变量（tcsh histdup 残留写法，赋值被忽略），
# 去重由下方 hist_* 选项覆盖，勿再加回。
HISTSIZE=50000
HISTFILE=$ZDOTDIR/.zsh_history
SAVEHIST=$HISTSIZE

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups     # includes hist_ignore_dups behavior
setopt hist_save_no_dups
setopt hist_find_no_dups

# History search with arrow keys (formerly keybindings.zsh)
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward
