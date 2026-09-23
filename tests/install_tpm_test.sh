#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/tests/lib/sandbox.sh"

# TPM 只负责托管插件，真正的插件目录要用户在 tmux 内按 `prefix + I` 才会克隆。
# 只装 TPM 不装插件时，catppuccin/tmux 与 tmux-resurrect 都缺席，tmux 会退回
# 默认绿底状态栏（2026-09-23 x64 实测：@thm_mantle 未定义、status-left 展开为空）。
# install.sh 部署完 ~/.tmux.conf 后必须把这个按键提示打出来。
HINT_KEY='C-a I'

# run_install <tmpdir> <home_dir> <bin_dir> <output_file>
run_install() {
    _tmpdir=$1
    _home_dir=$2
    _bin_dir=$3
    _output_file=$4

    (
        cd "$_tmpdir"
        PATH=$_bin_dir HOME=$_home_dir DOTFILES_OS=Linux DOTFILES_DISTRO=ubuntu DOTFILES_ARCH=x86_64 \
            /bin/bash "$REPO_ROOT/install.sh" >"$_output_file" 2>&1
    ) || fail "install.sh should succeed in the sandbox"
}

# make_fake_tmux <bin_dir>
make_fake_tmux() {
    printf '#!/bin/sh\nexit 0\n' >"$1/tmux"
    chmod +x "$1/tmux"
}

test_install_hints_prefix_key_when_tmux_plugins_missing() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output_file=$tmpdir/install.output

    mkdir -p "$home_dir" "$bin_dir"
    link_core_utils "$bin_dir"
    make_fake_tmux "$bin_dir"
    # TPM 本体在，但 ~/.tmux/plugins 下没有任何插件目录。
    mkdir -p "$home_dir/.tmux/plugins/tpm"
    printf '#!/bin/sh\n' >"$home_dir/.tmux/plugins/tpm/tpm"

    run_install "$tmpdir" "$home_dir" "$bin_dir" "$output_file"

    assert_contains "$HINT_KEY" "$output_file"

    rm -rf "$tmpdir"
}

test_install_hint_silent_when_tmux_plugins_installed() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output_file=$tmpdir/install.output

    mkdir -p "$home_dir" "$bin_dir"
    link_core_utils "$bin_dir"
    make_fake_tmux "$bin_dir"
    mkdir -p "$home_dir/.tmux/plugins/tpm"
    printf '#!/bin/sh\n' >"$home_dir/.tmux/plugins/tpm/tpm"
    # TPM 按仓库 basename 落盘：catppuccin/tmux -> ~/.tmux/plugins/tmux。
    mkdir -p "$home_dir/.tmux/plugins/tmux"

    run_install "$tmpdir" "$home_dir" "$bin_dir" "$output_file"

    assert_not_contains "$HINT_KEY" "$output_file"

    rm -rf "$tmpdir"
}

test_install_hint_silent_without_tmux() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output_file=$tmpdir/install.output

    mkdir -p "$home_dir" "$bin_dir"
    link_core_utils "$bin_dir"

    run_install "$tmpdir" "$home_dir" "$bin_dir" "$output_file"

    assert_not_contains "$HINT_KEY" "$output_file"

    rm -rf "$tmpdir"
}

test_install_hints_prefix_key_when_tmux_plugins_missing
test_install_hint_silent_when_tmux_plugins_installed
test_install_hint_silent_without_tmux

printf 'PASS: install tpm tests\n'
