#######################################################
# Path Management
#######################################################

# Add directories to the end of the path if they exist and not already in PATH
function pathappend() {
    for ARG in "$@"
    do
        if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
            PATH="${PATH:+"$PATH:"}$ARG"
        fi
    done
}

# Add directories to the beginning of the path if they exist and not already in PATH
function pathprepend() {
    for ARG in "$@"
    do
        if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
            PATH="$ARG${PATH:+":$PATH"}"
        fi
    done
}

# Personal binaries
pathprepend "$HOME/bin" "$HOME/sbin" "$HOME/.local/bin" "$HOME/local/bin" "$HOME/.bin"

# Rust / Cargo
pathappend "$HOME/.cargo/bin"

# Tmuxifier
pathappend "$HOME/.config/tmux/plugins/tmuxifier/bin"

# Platform-specific
# 用 zsh 内置 $OSTYPE 而非 $(uname) 子进程：启动即就绪，省两次 fork
# （env.zsh 同款写法）。
if [[ "$OSTYPE" == darwin* ]]; then
    # Homebrew (Apple Silicon + Intel) and MacPorts
    pathprepend "/opt/homebrew/bin"
    pathprepend "/usr/local/bin"
    pathprepend "/opt/local/bin"
    pathprepend "/opt/local/sbin"
    pathprepend "$HOME/.npm-global/bin"
elif [[ "$OSTYPE" == linux* ]]; then
    pathappend "/home/linuxbrew/.linuxbrew/bin"
    pathappend "/home/linuxbrew/.linuxbrew/sbin"
    pathappend "$HOME/.local/opt/node-current/bin"
    pathappend "$HOME/.npm-global/bin"
    pathappend "/usr/local/nodejs/bin"
    pathappend "$HOME/.bun/bin"
fi
