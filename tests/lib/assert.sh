# Shared shell assertions for repository tests.
#
# POSIX-only subset. Sourced by tests that use `#!/bin/sh` and tests
# that use `#!/bin/bash` alike. Functions exit with status 1 on hard
# failures; skip helpers emit SKIP markers and return the runner's
# SKIP_EXIT_CODE (default 77) so tests/run.sh can count them.

# Honor a caller-provided SKIP_EXIT_CODE so tests can override it if needed.
SKIP_EXIT_CODE=${SKIP_EXIT_CODE:-77}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_file_exists() {
    [ -e "$1" ] || fail "expected file to exist: $1"
}

assert_file_not_exists() {
    [ ! -e "$1" ] || fail "expected file not to exist: $1"
}

assert_executable() {
    [ -x "$1" ] || fail "expected executable file: $1"
}

assert_equals() {
    expected=$1
    actual=$2

    [ "$expected" = "$actual" ] || fail "expected '$expected' but got '$actual'"
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

assert_order() {
    first=$1
    second=$2
    file=$3

    first_line=$(grep -nF -- "$first" "$file" | head -n 1 | cut -d: -f1)
    second_line=$(grep -nF -- "$second" "$file" | head -n 1 | cut -d: -f1)

    [ -n "$first_line" ] || fail "expected '$first' in $file"
    [ -n "$second_line" ] || fail "expected '$second' in $file"
    [ "$first_line" -lt "$second_line" ] ||
        fail "expected '$first' to appear before '$second' in $file"
}

assert_matches() {
    pattern=$1
    file=$2

    if ! grep -qE "$pattern" "$file"; then
        fail "expected pattern '$pattern' in $file"
    fi
}

assert_not_matches() {
    pattern=$1
    file=$2

    if grep -qE "$pattern" "$file"; then
        fail "did not expect pattern '$pattern' in $file"
    fi
}

assert_output_contains() {
    needle=$1
    value=$2

    printf '%s\n' "$value" | grep -F -- "$needle" >/dev/null 2>&1 ||
        fail "expected output '$value' to contain '$needle'"
}

assert_output_not_contains() {
    needle=$1
    value=$2

    if printf '%s\n' "$value" | grep -F -- "$needle" >/dev/null 2>&1; then
        fail "did not expect output '$value' to contain '$needle'"
    fi
}

assert_exit_code() {
    expected=$1
    actual=$2
    label=${3:-command}

    [ "$expected" = "$actual" ] ||
        fail "expected $label to exit with $expected, got $actual"
}

# Accepts an octal mode (e.g. 755) and a path. stat -c '%a' is GNU stat;
# BSD stat uses -f '%Lp' — fall back to it for macOS / BSD test runs.
assert_file_mode() {
    expected_mode=$1
    path=$2

    if stat -c '%a' "$path" >/dev/null 2>&1; then
        actual_mode=$(stat -c '%a' "$path")
    else
        actual_mode=$(stat -f '%Lp' "$path" 2>/dev/null) ||
            fail "cannot stat mode of $path"
    fi

    [ "$actual_mode" = "$expected_mode" ] ||
        fail "expected $path mode $expected_mode, got $actual_mode"
}

# skip_unless <cmd>
# Prints a SKIP marker and returns SKIP_EXIT_CODE when the command is
# unavailable. The caller is expected to forward the return value:
#
#   skip_unless jq || return $?
#   ...uses jq...
skip_unless() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'SKIP: %s not available\n' "$1" >&2
        return "$SKIP_EXIT_CODE"
    fi
    return 0
}

# skip_unless_platform <os>
# Compares against uname -s.
skip_unless_platform() {
    if [ "$(uname -s)" != "$1" ]; then
        printf 'SKIP: requires %s, got %s\n' "$1" "$(uname -s)" >&2
        return "$SKIP_EXIT_CODE"
    fi
    return 0
}
