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
if [[ "$(uname)" == "Darwin" ]]; then
    # Apple Silicon Homebrew
    pathprepend "/opt/homebrew/bin"
    pathprepend "/usr/local/bin"
elif [[ "$(uname)" == "Linux" ]]; then
    pathappend "/home/linuxbrew/.linuxbrew/bin"
    pathappend "$HOME/.local/opt/node-current/bin"
    pathappend "$HOME/.npm-global/bin"
    pathappend "/usr/local/nodejs/bin"
fi
