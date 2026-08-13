#######################################################
# Shell Integrations (zoxide, tmuxifier, starship, conda)
#######################################################

# zoxide — smart cd replacement
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init --cmd cd zsh)"
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
