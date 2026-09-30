#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/tests/lib/sandbox.sh"

INSTALL_FILE=$REPO_ROOT/install.sh

# macOS install branch is exercised via a fake `uname -s` returning Darwin,
# no-op stubs for the commands install.sh probes, and a fake HOME so
# process_configs deploys macos_configs entries without touching the real user
# config. `borders` is deliberately NOT stubbed by default so the JankyBorders
# hint can be asserted; pass it in stub_commands when it should look installed.
# Skipped on non-Linux hosts because the sandbox relies on /bin/bash and the
# host's coreutils.
build_macos_sandbox() {
    stub_commands=$1
    user_bin_commands=${2:-}

    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output=$tmpdir/output.log

    mkdir -p "$home_dir" "$bin_dir"
    link_core_utils "$bin_dir"
    # brew = Brewfile hint, defaults = defaults.sh. The rest are macos_configs
    # check_cmd probes (aerospace/yabai/skhd/alacritty/ssh).
    for cmd in brew defaults $stub_commands; do
        printf '#!/bin/sh\nexit 0\n' >"$bin_dir/$cmd"
        chmod +x "$bin_dir/$cmd"
    done
    # Commands that must be discovered in the fake user-level bin directory
    # (~/.local/bin) rather than on PATH.
    if [ -n "$user_bin_commands" ]; then
        mkdir -p "$home_dir/.local/bin"
        for cmd in $user_bin_commands; do
            printf '#!/bin/sh\nexit 0\n' >"$home_dir/.local/bin/$cmd"
            chmod +x "$home_dir/.local/bin/$cmd"
        done
    fi
    # Fake uname returns Darwin so install.sh takes the macOS branch.
    # link_core_utils already symlinked the host uname; replace it.
    rm -f "$bin_dir/uname"
    printf '#!/bin/sh\nprintf "Darwin\\n"\n' >"$bin_dir/uname"
    chmod +x "$bin_dir/uname"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Darwin \
        /bin/bash "$INSTALL_FILE" >"$output" 2>&1 ||
        fail "install.sh should succeed on fake macOS"
}

test_install_macos_branch_runs_defaults_and_brewfile_hint() {
    skip_unless_platform Linux || return $?

    build_macos_sandbox "borders aerospace yabai skhd alacritty ssh"

    # macos_configs entries should be deployed.
    assert_file_exists "$home_dir/.ssh/config"
    assert_file_exists "$home_dir/.config/aerospace/aerospace.toml"
    assert_file_exists "$home_dir/.config/yabai/yabairc"
    assert_file_exists "$home_dir/.config/skhd/skhdrc"
    assert_file_exists "$home_dir/.config/alacritty/keys.toml"
    assert_file_exists "$home_dir/.config/alacritty/window.toml"

    # Brewfile hint must appear in the output (it does not run brew bundle,
    # only prints the command so the user runs it manually).
    assert_contains 'brew bundle --file' "$output"
    # defaults.sh is executed, so its "Setting macOS defaults..." banner
    # appears in the install.sh output.
    assert_contains 'Setting macOS defaults' "$output"

    rm -rf "$tmpdir"
}

# JankyBorders is only used by AeroSpace: yabai 6.0+ has no built-in window
# borders and the hackintosh has no Homebrew at all, so warning there is just
# noise pointing at a command that cannot run.
test_borders_hint_is_gated_on_aerospace() {
    skip_unless_platform Linux || return $?

    # AeroSpace installed, borders missing -> hint.
    build_macos_sandbox "aerospace yabai skhd alacritty ssh"
    assert_contains 'borders not found' "$output"
    rm -rf "$tmpdir"

    # yabai-only machine (the hackintosh) -> no hint.
    build_macos_sandbox "yabai skhd alacritty ssh"
    assert_not_contains 'borders not found' "$output"
    rm -rf "$tmpdir"
}

test_install_macos_branch_runs_defaults_and_brewfile_hint

# Regression: yabai is installed into ~/.local/bin (the repository's user-level
# CLI location), which only path.zsh adds to PATH. install.sh runs under bash, so
# it has to add that directory itself — otherwise the yabai configuration is
# silently skipped in every non-interactive run (measured on the hackintosh:
# yabai, herdr, herdr-report and trae-cli were all skipped).
test_user_level_bin_is_on_the_gate_path() {
    skip_unless_platform Linux || return $?

    build_macos_sandbox "skhd" "yabai"
    assert_file_exists "$home_dir/.config/yabai/yabairc"
    rm -rf "$tmpdir"
}

test_user_level_bin_is_on_the_gate_path
test_borders_hint_is_gated_on_aerospace

printf 'PASS: install macos tests\n'
