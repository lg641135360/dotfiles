#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"
TMUX_FILE=$REPO_ROOT/.config/shared/tmux/.tmux.conf
README_FILE=$REPO_ROOT/.config/shared/tmux/README.md
HELPER_FILE=$REPO_ROOT/.config/shared/tmux/tmux-tab-title
INSTALL_FILE=$REPO_ROOT/install.sh

TMP_DIRS=
LAST_SSH_HOME=

cleanup() {
    for dir in $TMP_DIRS; do
        [ -n "$dir" ] && rm -rf "$dir"
    done
}

trap cleanup EXIT HUP INT TERM

make_ssh_home() {
    LAST_SSH_HOME=$(mktemp -d)
    TMP_DIRS="$TMP_DIRS $LAST_SSH_HOME"
    mkdir -p "$LAST_SSH_HOME/.ssh"
    cat >"$LAST_SSH_HOME/.ssh/config"
}

format_title() {
    home=$1
    path=$2
    remote=${3:-}
    title=${4:-}

    HOME=$home "$HELPER_FILE" --format "$path" "$remote" "$title"
}

assert_host_segment() {
    expected=$1
    label=$2

    case "$label" in
        "$expected":*) ;;
        *) fail "expected host segment '$expected' in '$label'" ;;
    esac
}

test_catppuccin_options_use_current_names() {
    assert_contains "set -g @catppuccin_flavor 'mocha'" "$TMUX_FILE"
    assert_contains 'set -g @catppuccin_window_flags "none"' "$TMUX_FILE"
    assert_not_contains '@catppuccin_flavour' "$TMUX_FILE"
    assert_not_contains "set -g @catppuccin_window_status 'no'" "$TMUX_FILE"
    assert_not_contains '@catppuccin_window_default_text' "$TMUX_FILE"
    assert_not_contains '@catppuccin_window_current_fill' "$TMUX_FILE"
    assert_not_contains '@catppuccin_window_current_color' "$TMUX_FILE"
}

test_status_bar_has_balanced_left_and_right_modules() {
    assert_contains 'set -g status-interval 15' "$TMUX_FILE"
    assert_contains 'set -g status-left ""' "$TMUX_FILE"
    assert_contains 'set -g status-left-length 0' "$TMUX_FILE"
    assert_contains 'set -g status-right "#{prefix_highlight} #{E:@catppuccin_status_date_time}"' "$TMUX_FILE"
    assert_contains "set -g @catppuccin_date_time_text '%m/%d %H:%M'" "$TMUX_FILE"
    assert_not_contains 'tmux-plugins/tmux-continuum' "$TMUX_FILE"
    assert_not_contains '@continuum-' "$TMUX_FILE"
    assert_not_contains '@catppuccin_status_session' "$TMUX_FILE"
    assert_not_contains '@catppuccin_status_application' "$TMUX_FILE"
    assert_not_contains '@catppuccin_status_cpu' "$TMUX_FILE"
    assert_not_contains '@catppuccin_status_ram' "$TMUX_FILE"
    assert_not_contains '@catppuccin_status_battery' "$TMUX_FILE"
}

test_bottom_overrides_survive_plugin_defaults() {
    status_interval_line=$(awk '/set -g status-interval 15/ { print NR; exit }' "$TMUX_FILE")
    status_left_line=$(awk '/set -g status-left ""/ { print NR; exit }' "$TMUX_FILE")
    tpm_line=$(awk '/run '\''~\/.tmux\/plugins\/tpm\/tpm'\''/ { print NR; exit }' "$TMUX_FILE")

    [ -n "$status_interval_line" ] || fail "expected status-interval override"
    [ -n "$status_left_line" ] || fail "expected status-left hide override"
    [ -n "$tpm_line" ] || fail "expected TPM run line"
    [ "$status_interval_line" -gt "$tpm_line" ] ||
        fail "expected status-interval override after TPM so tmux-sensible cannot reset it"
    [ "$status_left_line" -gt "$tpm_line" ] ||
        fail "expected status-left hide override after TPM so Catppuccin cannot restore the session module"
}


test_daily_pane_workflow_enhancements() {
    assert_contains 'set -g set-clipboard on' "$TMUX_FILE"
    assert_contains 'bind C-a send-prefix' "$TMUX_FILE"
    assert_contains 'bind c new-window -c "#{pane_current_path}"' "$TMUX_FILE"
    assert_contains 'bind | split-window -h -c "#{pane_current_path}"' "$TMUX_FILE"
    assert_contains 'bind - split-window -v -c "#{pane_current_path}"' "$TMUX_FILE"
}

test_destroyed_sessions_detach_instead_of_switching() {
    assert_contains 'set -g detach-on-destroy on' "$TMUX_FILE"
    assert_not_contains 'set -g detach-on-destroy off' "$TMUX_FILE"
    assert_contains '当前 session 结束后会 detach 当前客户端' "$README_FILE"
    assert_contains '不会自动切回最近使用的其它 session' "$README_FILE"
}

test_pane_resize_and_border_visuals() {
    assert_contains 'bind H resize-pane -L 5' "$TMUX_FILE"
    assert_contains 'bind J resize-pane -D 5' "$TMUX_FILE"
    assert_contains 'bind K resize-pane -U 5' "$TMUX_FILE"
    assert_contains 'bind L resize-pane -R 5' "$TMUX_FILE"
    assert_contains 'set -g @catppuccin_pane_border_style "fg=#{@thm_surface_1}"' "$TMUX_FILE"
    assert_contains 'set -g @catppuccin_pane_active_border_style "fg=#{@thm_lavender}"' "$TMUX_FILE"
}

test_tab_titles_use_short_remote_path_helper() {
    assert_contains 'set -g @catppuccin_window_text " #($HOME/.config/tmux/tmux-tab-title #{pane_id})"' "$TMUX_FILE"
    assert_contains 'set -g @catppuccin_window_current_text " #($HOME/.config/tmux/tmux-tab-title #{pane_id})"' "$TMUX_FILE"
    assert_not_contains 'set -g @catppuccin_window_text " #W"' "$TMUX_FILE"
    assert_not_contains 'set -g @catppuccin_window_current_text " #W"' "$TMUX_FILE"
    assert_not_contains 'pane_current_command' "$TMUX_FILE"
}

test_tab_title_helper_formats_path_and_remote_context() {
    assert_executable "$HELPER_FILE"
    assert_contains '.config/shared/tmux/tmux-tab-title|~/.config/tmux/tmux-tab-title|Tmux tab title script' "$INSTALL_FILE"

    local_label=$(format_title /home/rikoo "/home/rikoo/Documents/dotfiles" "" "")
    generic_label=$(format_title /home/rikoo "/home/rikoo/Documents/current" "" "")
    root_label=$(format_title /home/rikoo "/" "" "")
    empty_label=$(format_title /home/rikoo "" "" "")
    dot_label=$(format_title /home/rikoo "." "" "")
    remote_label=$(format_title /home/rikoo "/srv/api" "deploy@db01.example.com" "")
    remote_current_label=$(format_title /home/rikoo "/srv/current" "deploy@db01.example.com" "")
    remote_empty_label=$(format_title /home/rikoo "" "deploy@db01.example.com" "")
    long_label=$(HOME=/home/rikoo TMUX_TAB_TITLE_MAX=18 "$HELPER_FILE" --format "/srv/apps/very-long-service-name/current" "deploy@production.example.com" "")

    assert_equals "dotfiles" "$local_label"
    assert_equals "Documents/current" "$generic_label"
    assert_equals "~" "$root_label"
    assert_equals "~" "$empty_label"
    assert_equals "~" "$dot_label"
    assert_output_not_contains "L:" "$local_label"
    assert_host_segment "db01" "$remote_label"
    assert_output_contains "api" "$remote_label"
    assert_equals "db01:srv/current" "$remote_current_label"
    assert_equals "db01:~" "$remote_empty_label"
    [ "${#long_label}" -le 18 ] || fail "expected long tab label to be truncated to 18 chars, got '$long_label'"
    printf '%s\n' "$long_label" | grep -F -- "production:" >/dev/null 2>&1 ||
        fail "expected long remote label to keep the remote name"
}

test_tab_title_helper_prefers_explicit_ssh_aliases() {
    make_ssh_home <<'EOF'
Host prod
  HostName 203.0.113.42

Host buildbox
  HostName build.internal.example.com
EOF

    uri_label=$(format_title "$LAST_SSH_HOME" "ssh://rikoo@203.0.113.42:22/home/app" "" "")
    scp_label=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@203.0.113.42:/srv/api" "")
    fqdn_label=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@build.internal.example.com:/srv/api" "")

    assert_host_segment "prod" "$uri_label"
    assert_host_segment "prod" "$scp_label"
    assert_host_segment "buildbox" "$fqdn_label"
    assert_output_not_contains "113.42" "$uri_label"
    assert_output_not_contains "203.0.113.42" "$scp_label"
    assert_output_not_contains "build.internal.example.com" "$fqdn_label"
}

test_tab_title_helper_uses_no_alias_host_fallbacks() {
    make_ssh_home <<'EOF'
Host unrelated
  HostName 198.51.100.7
EOF

    label_192=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@192.168.1.1:/srv/api" "")
    label_10=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@10.20.30.40:/srv/api" "")
    label_fqdn=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@db01.example.com:/srv/api" "")
    title_tail_pair=$(format_title "$LAST_SSH_HOME" "/tmp/local" "" "rikoo@1.1:/srv/api")

    assert_host_segment "1.1" "$label_192"
    assert_host_segment "30.40" "$label_10"
    assert_host_segment "db01" "$label_fqdn"
    assert_equals "1.1:api" "$title_tail_pair"
}

test_tab_title_helper_skips_complex_ssh_config() {
    make_ssh_home <<'EOF'
Host *.prod
  HostName db01.internal.example.com

Host 10.*
  HostName 10.20.30.40

Host *
  HostName fallback.example.com

Host prod prod-alt
  HostName 203.0.113.42

Include other.conf

Match host matched.example.com
  HostName match-alias.example.com
EOF

    wildcard_fqdn=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@db01.internal.example.com:/srv/api" "")
    wildcard_ipv4=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@10.20.30.40:/srv/api" "")
    host_star=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@fallback.example.com:/srv/api" "")
    multi_alias=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@203.0.113.42:/srv/api" "")
    match_label=$(format_title "$LAST_SSH_HOME" "/srv/api" "rikoo@matched.example.com:/srv/api" "")

    assert_host_segment "db01" "$wildcard_fqdn"
    assert_host_segment "30.40" "$wildcard_ipv4"
    assert_host_segment "fallback" "$host_star"
    assert_host_segment "113.42" "$multi_alias"
    assert_host_segment "matched" "$match_label"
    assert_output_not_contains "*.prod" "$wildcard_fqdn"
    assert_output_not_contains "10.*" "$wildcard_ipv4"
    assert_output_not_contains "*:" "$host_star"
    assert_output_not_contains "prod:" "$multi_alias"
    assert_output_not_contains "prod-alt" "$multi_alias"
}

test_window_navigation_enhancements() {
    assert_contains 'bind w choose-tree -Zw' "$TMUX_FILE"
    assert_contains 'bind Tab last-window' "$TMUX_FILE"
}

test_readme_documents_status_bar_layout() {
    assert_contains '状态栏' "$README_FILE"
    assert_contains '左侧隐藏 session 名' "$README_FILE"
    assert_contains '右侧显示 Prefix/Copy 状态和日期时间' "$README_FILE"
    assert_contains '本地 tab 不加 `L:` 前缀' "$README_FILE"
    assert_contains '本地默认显示项目名' "$README_FILE"
    assert_contains '必要时显示父级/项目名' "$README_FILE"
    assert_contains '远程优先显示 SSH `Host` 别名' "$README_FILE"
    assert_contains '无别名的 IPv4 只显示最后两段' "$README_FILE"
    assert_contains '不显示当前 shell 或命令名' "$README_FILE"
    assert_contains '不自动保存' "$README_FILE"
    assert_not_contains 'tmux-continuum' "$README_FILE"
    assert_not_contains '每 15 分钟自动保存' "$README_FILE"
}

test_readme_documents_window_navigation() {
    assert_contains 'Ctrl+a + w' "$README_FILE"
    assert_contains '树状选择器' "$README_FILE"
    assert_contains 'Ctrl+a + Tab' "$README_FILE"
    assert_contains '上一个窗口' "$README_FILE"
}

test_catppuccin_options_use_current_names
test_status_bar_has_balanced_left_and_right_modules
test_bottom_overrides_survive_plugin_defaults
test_daily_pane_workflow_enhancements
test_destroyed_sessions_detach_instead_of_switching
test_pane_resize_and_border_visuals
test_tab_titles_use_short_remote_path_helper
test_tab_title_helper_formats_path_and_remote_context
test_tab_title_helper_prefers_explicit_ssh_aliases
test_tab_title_helper_uses_no_alias_host_fallbacks
test_tab_title_helper_skips_complex_ssh_config
test_window_navigation_enhancements
test_readme_documents_status_bar_layout
test_readme_documents_window_navigation

printf 'PASS: tmux status tests\n'
