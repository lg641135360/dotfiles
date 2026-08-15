#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
STARSHIP_FILE=$REPO_ROOT/.config/shared/starship.toml
INTEGRATIONS_FILE=$REPO_ROOT/.config/shared/zsh/integrations.zsh
ZSHRC_FILE=$REPO_ROOT/.config/shared/zsh/.zshrc
INSTALL_FILE=$REPO_ROOT/install.sh

. "$REPO_ROOT/tests/lib/assert.sh"

# starship 配置文件存在且可被 starship 解析
test_starship_config_exists() {
    [ -f "$STARSHIP_FILE" ] || { echo "FAIL: starship.toml not found"; exit 1; }
}

# starship init 必须在 integrations.zsh 中（替代 p10k source）
test_starship_init_in_integrations() {
    assert_contains 'starship init zsh' "$INTEGRATIONS_FILE"
    assert_contains 'command -v starship' "$INTEGRATIONS_FILE"
}

# .zshrc 不应再包含 p10k instant prompt 块
test_zshrc_no_p10k_instant_prompt() {
    assert_not_contains 'p10k-instant-prompt' "$ZSHRC_FILE"
    assert_not_contains 'powerlevel10k' "$ZSHRC_FILE"
}

# integrations.zsh 不应再 source .p10k.zsh
test_integrations_no_p10k_source() {
    assert_not_contains '.p10k.zsh' "$INTEGRATIONS_FILE"
    assert_not_contains 'POWERLEVEL9K' "$INTEGRATIONS_FILE"
}

# install.sh 必须包含 starship.toml 部署项
test_install_deploys_starship_config() {
    assert_contains '.config/shared/starship.toml' "$INSTALL_FILE"
    assert_contains '~/.config/starship.toml' "$INSTALL_FILE"
}

# starship.toml 必须包含核心段落：directory/git_branch/git_status/character
test_starship_config_has_core_modules() {
    assert_contains '[directory]' "$STARSHIP_FILE"
    assert_contains '[git_branch]' "$STARSHIP_FILE"
    assert_contains '[git_status]' "$STARSHIP_FILE"
    assert_contains '[character]' "$STARSHIP_FILE"
    assert_contains '$nodejs' "$STARSHIP_FILE"
    assert_contains '$bun' "$STARSHIP_FILE"
    assert_contains '$docker_context' "$STARSHIP_FILE"
    assert_contains 'right_format = """$time$cmd_duration"""' "$STARSHIP_FILE"
    assert_contains 'ignore_base = true' "$STARSHIP_FILE"
    assert_contains "error_symbol = '[❯](bold fg:red)'" "$STARSHIP_FILE"
    assert_not_contains 'bg:' "$STARSHIP_FILE"
}

# starship.toml 用 Nerd Font 图标（与 foot/alacritty 字体配置一致）
test_starship_uses_nerd_font_icons() {
    assert_contains 'symbol = ' "$STARSHIP_FILE"
}

test_starship_config_exists
test_starship_init_in_integrations
test_zshrc_no_p10k_instant_prompt
test_integrations_no_p10k_source
test_install_deploys_starship_config
test_starship_config_has_core_modules
test_starship_uses_nerd_font_icons

printf 'PASS: starship config tests\n'
