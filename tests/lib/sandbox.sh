# Shared test sandbox helpers.
#
# POSIX-only subset. Provides fake-PATH construction utilities used by
# install.sh and script tests that must run install.sh against a
# hermetic bin directory.
#
# Usage:
#   . "$REPO_ROOT/tests/lib/sandbox.sh"
#   bin_dir=$tmpdir/bin
#   mkdir -p "$bin_dir"
#   link_core_utils "$bin_dir"          # bash basename cp date diff ...
#   link_cmd jq "$bin_dir"              # extra command
#   # or: extra_cmds='jq chmod'
#   #     link_core_utils "$bin_dir" extra_cmds

# link_cmd <cmd> <bin_dir>
# Symlinks an existing command into the fake bin dir. Fails loudly if
# the command is missing on the host so tests do not silently skip
# commands they assume are present.
#
# `command -v` may resolve to a bare name (shell function / alias /
# builtin) instead of a path — e.g. editor shell-integration scripts
# inject cp/mv wrapper functions that leak into child shells. Linking
# to a bare name would create a self-referential dangling symlink, so
# in that case fall back to searching PATH for the real executable.
link_cmd() {
    cmd=$1
    target_dir=$2
    src=$(command -v "$cmd") || {
        printf 'link_cmd: %s not found on host PATH\n' "$cmd" >&2
        return 1
    }
    case $src in
        */*) ;;
        *)
            src=""
            oldifs=$IFS
            IFS=:
            for dir in $PATH; do
                if [ -f "$dir/$cmd" ] && [ -x "$dir/$cmd" ]; then
                    src="$dir/$cmd"
                    break
                fi
            done
            IFS=$oldifs
            [ -n "$src" ] || {
                printf 'link_cmd: %s resolves to a shell function/alias/builtin, no executable found on PATH\n' "$cmd" >&2
                return 1
            }
            ;;
    esac
    ln -s "$src" "$target_dir/$cmd"
}

# link_core_utils <bin_dir> [extra_cmds_var]
# Symlinks the baseline command set that install.sh needs in every
# sandboxed run. Callers may pass the name of a shell variable holding
# additional commands; this keeps the call site short while still
# allowing per-test additions.
#
#   extra_cmds='jq chmod cmp mktemp'
#   link_core_utils "$bin_dir" extra_cmds
link_core_utils() {
    target_dir=$1
    extra_cmds_var=${2:-}

    # Baseline set: install.sh check_dependencies + the utilities the
    # script body actually invokes. Mirrors the smallest PATH that the
    # existing tests have already validated.
    for cmd in bash basename cp date diff dirname find grep head ln \
        mkdir mv pwd rm sed sort tail uname; do
        link_cmd "$cmd" "$target_dir"
    done

    if [ -n "$extra_cmds_var" ]; then
        eval "extra_list=\$$extra_cmds_var"
        for cmd in $extra_list; do
            link_cmd "$cmd" "$target_dir"
        done
    fi
}

# make_fake_cmd <bin_dir> <name> <body...>
# Writes a fake executable into the sandbox bin dir. The body is a
# literal here-doc; callers are responsible for any quoting. The
# resulting file is marked executable.
#
#   make_fake_cmd "$bin_dir" uname <<'EOF'
#   #!/bin/sh
#   printf 'aarch64\n'
#   EOF
make_fake_cmd() {
    target_dir=$1
    name=$2
    cat >"$target_dir/$name"
    chmod +x "$target_dir/$name"
}

# prepare_install_path <bin_dir> [extra_cmds_var]
# Convenience wrapper that links the baseline utils and stubs out the
# Wayland-session commands install.sh probes for (niri, alacritty).
# Equivalent to the previous per-test `prepare_install_path` helper.
prepare_install_path() {
    target_dir=$1
    extra_cmds_var=${2:-}

    if [ -n "$extra_cmds_var" ]; then
        link_core_utils "$target_dir" "$extra_cmds_var"
    else
        link_core_utils "$target_dir"
    fi

    # niri and alacritty are probed by install.sh's wayland branch;
    # stub them as no-ops so the deployment path executes.
    for fake in niri alacritty; do
        if [ ! -e "$target_dir/$fake" ]; then
            printf '#!/bin/sh\nexit 0\n' >"$target_dir/$fake"
            chmod +x "$target_dir/$fake"
        fi
    done
}
