#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
. "$REPO_ROOT/tests/lib/sandbox.sh"

INSTALL_FILE=$REPO_ROOT/install.sh

# macOS install branch is exercised via a fake `uname -s` returning Darwin,
# fake `brew`/`defaults`/`aerospace`/`alacritty`/`ssh` commands, and a fake
# HOME so process_configs deploys macos_configs entries without touching the
# real user config. Skipped on non-Linux hosts because the sandbox relies on
# /bin/bash and the host's coreutils.
test_install_macos_branch_runs_defaults_and_brewfile_hint() {
    skip_unless_platform Linux || return $?

    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    bin_dir=$tmpdir/bin
    output=$tmpdir/output.log

    mkdir -p "$home_dir" "$bin_dir"
    link_core_utils "$bin_dir"
    # macOS install probes: brew (Brewfile hint), defaults (defaults.sh),
    # borders (optional warn), aerospace + alacritty + ssh (macos_configs
    # check_cmd). Stub them as no-ops so the deployment path executes.
    for cmd in brew defaults borders aerospace alacritty ssh; do
        printf '#!/bin/sh\nexit 0\n' >"$bin_dir/$cmd"
        chmod +x "$bin_dir/$cmd"
    done
    # Fake uname returns Darwin so install.sh takes the macOS branch.
    # link_core_utils already symlinked the host uname; replace it.
    rm -f "$bin_dir/uname"
    printf '#!/bin/sh\nprintf "Darwin\\n"\n' >"$bin_dir/uname"
    chmod +x "$bin_dir/uname"

    PATH=$bin_dir HOME=$home_dir DOTFILES_OS=Darwin \
        /bin/bash "$INSTALL_FILE" >"$output" 2>&1 ||
        fail "install.sh should succeed on fake macOS"

    # macos_configs entries should be deployed.
    assert_file_exists "$home_dir/.ssh/config"
    assert_file_exists "$home_dir/.config/aerospace/aerospace.toml"
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

test_install_macos_branch_runs_defaults_and_brewfile_hint

printf 'PASS: install macos tests\n'
