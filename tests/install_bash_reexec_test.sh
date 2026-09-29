#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

INSTALL_FILE=$REPO_ROOT/install.sh

# install.sh 需要 Bash >= 4.3（process_configs 的 `local -n`、clean_old_backups
# 的 `mapfile`）。macOS 自带 Bash 3.2（/bin/bash），所以脚本必须在过旧
# 解释器下 re-exec 一个现代 Bash（Intel macOS + MacPorts → /opt/local/bin/bash），
# 否则 `./install.sh` 会在部署任何文件前就报 `local: -n: invalid option` 退出。
#
# 该守卫只在 Bash < 4 下触发；Linux 等自带 Bash 5 的环境无从复现，跳过。
host_bash_major=$(/bin/bash -c 'printf "%s" "${BASH_VERSINFO[0]}"' 2>/dev/null || printf 0)
if [ "${host_bash_major:-0}" -ge 4 ]; then
    printf 'SKIP: /bin/bash is %s (>= 4); re-exec guard only applies to Bash < 4.3\n' \
        "$host_bash_major" >&2
    exit 77
fi

# 用 stub 冒充“现代 Bash”：它记录自己收到的参数并退出，从而在只有 Bash 3.2
# 的机器上也能断言 re-exec 分派本身，而不需要真的装一个 Bash 5。
test_old_bash_reexecs_into_modern_bash() {
    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    stub=$tmpdir/modern-bash
    capture=$tmpdir/capture
    output=$tmpdir/output.log

    mkdir -p "$home_dir"
    cat >"$stub" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" >"$REEXEC_CAPTURE"
exit 0
EOF
    chmod +x "$stub"

    REEXEC_CAPTURE=$capture \
    DOTFILES_BASH=$stub \
    HOME=$home_dir \
        /bin/bash "$INSTALL_FILE" sentinel-arg >"$output" 2>&1 ||
        fail "install.sh should hand off to the modern bash instead of failing"

    assert_file_exists "$capture"
    assert_contains "$INSTALL_FILE" "$capture"
    assert_contains 'sentinel-arg' "$capture"
    # 分派后旧解释器不应继续跑 main。
    assert_not_contains 'Processing shared configurations' "$output"

    rm -rf "$tmpdir"
}

# 找不到现代 Bash 时必须给出可执行的补救指引（macOS x86 走 MacPorts）。
test_missing_modern_bash_reports_port_remedy() {
    if [ -x /opt/local/bin/bash ] || [ -x /usr/local/bin/bash ] || [ -x /opt/homebrew/bin/bash ]; then
        printf 'SKIP: a modern bash is installed; cannot exercise the missing-bash path\n' >&2
        return 0
    fi

    tmpdir=$(mktemp -d)
    home_dir=$tmpdir/home
    output=$tmpdir/output.log

    mkdir -p "$home_dir"
    DOTFILES_BASH=$tmpdir/nope \
    HOME=$home_dir \
        /bin/bash "$INSTALL_FILE" >"$output" 2>&1 && rc=0 || rc=$?

    [ "$rc" -ne 0 ] || fail "install.sh should fail when no modern bash is available"
    assert_contains 'requires Bash >= 4.3' "$output"
    assert_contains 'port install bash' "$output"

    rm -rf "$tmpdir"
}

test_install_sh_documents_macports_bash() {
    assert_contains '/opt/local/bin/bash' "$INSTALL_FILE"
}

test_old_bash_reexecs_into_modern_bash
test_missing_modern_bash_reports_port_remedy
test_install_sh_documents_macports_bash

printf 'PASS: install bash re-exec tests\n'
