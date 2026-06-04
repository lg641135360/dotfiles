# Shared shell assertions for repository tests.

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
