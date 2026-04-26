#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TMUX_FILE=$REPO_ROOT/.config/shared/tmux/.tmux.conf
README_FILE=$REPO_ROOT/.config/shared/tmux/README.md
HELPER_FILE=$REPO_ROOT/.config/shared/tmux/tmux-tab-title
INSTALL_FILE=$REPO_ROOT/install.sh

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    needle=$1
    file=$2

    if ! grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "expected '$needle' in $file"
    fi
}

assert_not_contains() {
    needle=$1
    file=$2

    if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
        fail "did not expect '$needle' in $file"
    fi
}

assert_equals() {
    expected=$1
    actual=$2

    [ "$expected" = "$actual" ] ||
        fail "expected '$expected' but got '$actual'"
}

assert_executable() {
    file=$1

    [ -x "$file" ] || fail "expected executable file: $file"
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

    local_label=$(HOME=/home/rikoo "$HELPER_FILE" --format "/home/rikoo/Documents/dotfiles" "" "")
    remote_label=$(HOME=/home/rikoo "$HELPER_FILE" --format "/var/www/current" "deploy@prod.example.com" "")
    long_label=$(HOME=/home/rikoo TMUX_TAB_TITLE_MAX=28 "$HELPER_FILE" --format "/srv/apps/very-long-service-name/current" "deploy@production.example.com" "")

    assert_equals "~/Documents/dotfiles" "$local_label"
    assert_equals "prod:/var/www/current" "$remote_label"
    [ "${#long_label}" -le 28 ] || fail "expected long tab label to be truncated to 28 chars, got '$long_label'"
    printf '%s\n' "$long_label" | grep -F -- "production:" >/dev/null 2>&1 ||
        fail "expected long remote label to keep the remote name"
}

test_window_navigation_enhancements() {
    assert_contains 'bind w choose-tree -Zw' "$TMUX_FILE"
    assert_contains 'bind Tab last-window' "$TMUX_FILE"
}

test_readme_documents_status_bar_layout() {
    assert_contains '状态栏' "$README_FILE"
    assert_contains '左侧隐藏 session 名' "$README_FILE"
    assert_contains '右侧显示 Prefix/Copy 状态和日期时间' "$README_FILE"
    assert_contains '窗口列表标题显示短路径' "$README_FILE"
    assert_contains '远程连接' "$README_FILE"
    assert_contains '不显示当前 shell 或命令名' "$README_FILE"
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
test_pane_resize_and_border_visuals
test_tab_titles_use_short_remote_path_helper
test_tab_title_helper_formats_path_and_remote_context
test_window_navigation_enhancements
test_readme_documents_status_bar_layout
test_readme_documents_window_navigation

printf 'PASS: tmux status tests\n'
