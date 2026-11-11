#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$REPO_ROOT/tests/lib/assert.sh"

WORKFLOW=$REPO_ROOT/.github/workflows/ci.yml
ROOT_README=$REPO_ROOT/README.md

# CI is the only gate outside the local checkout: without it a regression can
# reach origin/main even though every local test is green. These assertions
# pin the minimum contract (fast suite + whitespace check on the pushed range),
# so editing the workflow cannot silently drop a gate.

test_workflow_file_exists() {
    assert_file_exists "$WORKFLOW"
}

test_workflow_triggers_on_push_and_pull_request() {
    assert_contains 'push:' "$WORKFLOW"
    assert_contains 'pull_request:' "$WORKFLOW"
}

test_workflow_runs_fast_suite_on_ubuntu() {
    assert_contains 'runs-on: ubuntu-latest' "$WORKFLOW"
    assert_contains './tests/run.sh fast' "$WORKFLOW"
}

test_workflow_checks_whitespace_on_pushed_range() {
    assert_contains 'git diff --check' "$WORKFLOW"
    # A bare `git diff --check` is a no-op in a fresh CI checkout (nothing is
    # modified); only the range form inspects the pushed commit.
    assert_contains 'HEAD^' "$WORKFLOW"
}

test_workflow_initializes_submodules() {
    assert_contains 'submodules: recursive' "$WORKFLOW"
}

test_readme_documents_ci() {
    assert_contains 'GitHub Actions' "$ROOT_README"
    assert_contains '.github/workflows/ci.yml' "$ROOT_README"
}

test_workflow_file_exists
test_workflow_triggers_on_push_and_pull_request
test_workflow_runs_fast_suite_on_ubuntu
test_workflow_checks_whitespace_on_pushed_range
test_workflow_initializes_submodules
test_readme_documents_ci

printf 'PASS: ci workflow tests\n'
