# 确保 ZSHDOTDIR 有默认值（若外部未定义）
: "${ZSHDOTDIR:=$HOME/.config/zsh}"

# 加载 Zap 插件管理器
[ -f "$HOME/.local/share/zap/zap.zsh" ] && source "$HOME/.local/share/zap/zap.zsh"

# 仅交互 shell 继续，脚本模式尽早返回（放在插件前减少开销）
[[ $- != *i* ]] && return

# history 设置
HISTFILE="$ZSHDOTDIR/.zsh_history"
HISTSIZE=20000
SAVEHIST=20000
mkdir -p -- "${HISTFILE%/*}" 2>/dev/null || true
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_FIND_NO_DUPS \
	INC_APPEND_HISTORY SHARE_HISTORY

# 本地自定义（存在才加载）
[ -r "$HOME/.config/zsh/aliases.zsh" ] && plug "$HOME/.config/zsh/aliases.zsh"
[ -r "$HOME/.config/zsh/exports.zsh" ] && plug "$HOME/.config/zsh/exports.zsh"

# 插件顺序：语法高亮放最后
plug "zap-zsh/supercharge"
plug "zap-zsh/vim"
# plug "zap-zsh/zap-prompt"
plug "hlissner/zsh-autopair"
plug "zsh-users/zsh-autosuggestions"
# plug "zap-zsh/atmachine"
plug "romkatv/powerlevel10k"
plug "zap-zsh/fzf"
plug "rupa/z"
plug "zsh-users/zsh-history-substring-search"
plug "zsh-users/zsh-syntax-highlighting"  # 必须最后

# history substring search 键位（方向键或 Ctrl-P/N 二选一，默认给 Ctrl-P/N）
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# 常用便捷 setopt（按需保留）
setopt AUTO_CD GLOB_DOTS EXTENDED_GLOB

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniforge/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniforge/etc/profile.d/conda.sh" ]; then
        . "/opt/miniforge/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniforge/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
