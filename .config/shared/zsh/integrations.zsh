#######################################################
# Shell Integrations (zoxide, tmuxifier, starship, conda)
#######################################################

# zoxide — smart cd replacement
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init --cmd cd zsh)"

    # 官方 __zoxide_z_complete 对「cd <前缀>」只跑 _cd -/；本地无匹配
    # 时 return 0，Tab 像没反应。只包这一支：有匹配用本地，没有再
    # query --list。空格后再 Tab 等其余分支走 orig，不复制上游。
    functions[_zoxide_z_complete_orig]=$functions[__zoxide_z_complete]
    function __zoxide_z_complete() {
        if [[ ${#words[@]} -eq 2 && ${#words[@]} -eq $CURRENT ]]; then
            _cd -/
            (( compstate[nmatches] > 0 )) && return 0
            local -a zoxide_matches
            zoxide_matches=(${(f)"$(\command zoxide query --exclude "$(__zoxide_pwd || \builtin true)" --list -- "${words[2]}" 2>/dev/null)"})
            (( ${#zoxide_matches} )) && compadd -U -Q -f -S / -- "${zoxide_matches[@]}"
            return 0
        fi
        _zoxide_z_complete_orig
    }
fi

# tmuxifier — tmux session layouts
if command -v tmuxifier &> /dev/null; then
    eval "$(tmuxifier init -)"
fi

# Starship prompt — 单一 Rust 二进制，无 gitstatus 版本依赖
# 配置：~/.config/starship.toml（由 install.sh 从 .config/shared/starship.toml 部署）
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# Conda (lazy-loaded for faster shell startup)
# Only activates on first `conda` command invocation
if [[ -x "/opt/miniforge/bin/conda" ]]; then
    conda() {
        export PATH="/opt/miniforge/bin:$PATH"
        unset -f conda
        __conda_setup="$('/opt/miniforge/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        else
            [ -f "/opt/miniforge/etc/profile.d/conda.sh" ] && . "/opt/miniforge/etc/profile.d/conda.sh"
        fi
        unset __conda_setup
        conda "$@"
    }
fi
