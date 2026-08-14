#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO_ROOT/scripts"

# Test 1: same-day entries are reversed (newest = last in document).
npx tsx -e '
import { splitEntries, sortEntriesNewestFirst } from "./archive_trace.ts";
const text = `# Trace\n\n## 2026-08-14 — first\n\nbody\n\n## 2026-08-14 — second\n\nbody\n\n## 2026-08-14 — third\n\nbody\n`;
const sorted = sortEntriesNewestFirst(splitEntries(text).subEntries);
const headings = sorted.map((entry) => entry.heading);
const expected = [
  "## 2026-08-14 — third",
  "## 2026-08-14 — second",
  "## 2026-08-14 — first",
];
if (JSON.stringify(headings) !== JSON.stringify(expected)) {
  console.error(`unexpected same-day order: ${JSON.stringify(headings)}`);
  process.exit(1);
}
'

# Test 2: format 1 (## date + ### subsections) splits correctly.
npx tsx -e '
import { splitEntries } from "./archive_trace.ts";
const text = `# Trace\n\n## 2026-08-14\n\n### first sub\n\nbody a\n\n### second sub\n\nbody b\n`;
const { subEntries } = splitEntries(text);
if (subEntries.length !== 2) {
  console.error(`expected 2 sub-entries, got ${subEntries.length}`);
  process.exit(1);
}
if (subEntries[0].heading !== "### first sub") {
  console.error(`unexpected first heading: ${subEntries[0].heading}`);
  process.exit(1);
}
if (subEntries[1].heading !== "### second sub") {
  console.error(`unexpected second heading: ${subEntries[1].heading}`);
  process.exit(1);
}
'

# Test 3: format 1 preamble (text between ## date and first ###) is preserved.
npx tsx -e '
import { splitEntries } from "./archive_trace.ts";
const text = `# Trace\n\n## 2026-08-14\n\npreamble line\n\n### first sub\n\nbody a\n`;
const { subEntries } = splitEntries(text);
if (subEntries.length !== 1) {
  console.error(`expected 1 sub-entry, got ${subEntries.length}`);
  process.exit(1);
}
if (!subEntries[0].rawText.includes("preamble line")) {
  console.error(`preamble not preserved in rawText: ${subEntries[0].rawText}`);
  process.exit(1);
}
'

# Test 4: empty trace (only header, no dated entries).
npx tsx -e '
import { splitEntries } from "./archive_trace.ts";
const text = `# Trace\n\n> maintenance rules only\n`;
const { header, subEntries } = splitEntries(text);
if (subEntries.length !== 0) {
  console.error(`expected 0 sub-entries for empty trace, got ${subEntries.length}`);
  process.exit(1);
}
if (!header.includes("maintenance rules")) {
  console.error(`header not preserved: ${header}`);
  process.exit(1);
}
'

# Test 5: --keep validation rejects non-integer values.
npx tsx -e '
import { main } from "./archive_trace.ts";
const rc = main(["--keep", "foo"]);
if (rc !== 2) {
  console.error(`expected exit code 2 for --keep foo, got ${rc}`);
  process.exit(1);
}
const rc2 = main(["--keep", "-1"]);
if (rc2 !== 2) {
  console.error(`expected exit code 2 for --keep -1, got ${rc2}`);
  process.exit(1);
}
const rc3 = main(["--keep", "2.5"]);
if (rc3 !== 2) {
  console.error(`expected exit code 2 for --keep 2.5, got ${rc3}`);
  process.exit(1);
}
'

# Test 6: parseArgs supports --flag=value syntax.
npx tsx -e '
import { parseArgs } from "./lib.ts";
const args = parseArgs(["--dry-run", "--keep=10"]);
if (args["dry-run"] !== true) {
  console.error(`expected dry-run=true, got ${args["dry-run"]}`);
  process.exit(1);
}
if (args["keep"] !== "10") {
  console.error(`expected keep="10", got ${args["keep"]}`);
  process.exit(1);
}
'

# Test 7: cross-month sorting (newest month first, then by document order within same day).
npx tsx -e '
import { splitEntries, sortEntriesNewestFirst } from "./archive_trace.ts";
const text = `# Trace\n\n## 2026-07-01 — july entry\n\nbody\n\n## 2026-08-14 — aug entry\n\nbody\n`;
const { subEntries } = splitEntries(text);
const sorted = sortEntriesNewestFirst(subEntries);
if (sorted.length !== 2) {
  console.error(`expected 2 entries, got ${sorted.length}`);
  process.exit(1);
}
if (sorted[0].day !== "2026-08-14") {
  console.error(`expected 2026-08-14 first, got ${sorted[0].day}`);
  process.exit(1);
}
if (sorted[1].day !== "2026-07-01") {
  console.error(`expected 2026-07-01 second, got ${sorted[1].day}`);
  process.exit(1);
}
'

# Test 8: parseArgs consumes the next non-flag token as the value.
npx tsx -e '
import { parseArgs } from "./lib.ts";
const args = parseArgs(["--dry-run", "--out", "x"]);
if (args["dry-run"] !== true) {
  console.error(`expected dry-run=true, got ${args["dry-run"]}`);
  process.exit(1);
}
if (args["out"] !== "x") {
  console.error(`expected out="x", got ${args["out"]}`);
  process.exit(1);
}
'

# Test 9: parseArgs does not consume a following --flag as a value.
npx tsx -e '
import { parseArgs } from "./lib.ts";
const args = parseArgs(["--flag", "--other"]);
if (args["flag"] !== true) {
  console.error(`expected flag=true, got ${args["flag"]}`);
  process.exit(1);
}
if (args["other"] !== true) {
  console.error(`expected other=true, got ${args["other"]}`);
  process.exit(1);
}
'

# Test 10: parseArgs handles empty argv and unknown flags.
npx tsx -e '
import { parseArgs } from "./lib.ts";
const empty = parseArgs([]);
if (Object.keys(empty).length !== 0) {
  console.error(`expected empty object for empty argv, got ${JSON.stringify(empty)}`);
  process.exit(1);
}
// Unknown flags follow the same rule as known ones: bare --flag becomes true.
const unknown = parseArgs(["--unknown-flag"]);
if (unknown["unknown-flag"] !== true) {
  console.error(`expected unknown-flag=true, got ${unknown["unknown-flag"]}`);
  process.exit(1);
}
'

# Test 11: end-to-end dry-run against the real trace.md returns 0 without
# writing anything. main() reads from the real repoRoot (no env override),
# so this validates the dry-run code path returns 0 without throwing.
# Full write-path e2e is exercised by manual invocation per AGENTS.md.
npx tsx -e '
import { main } from "./archive_trace.ts";
const rc = main(["--dry-run", "--keep", "1"]);
if (rc !== 0) {
  console.error(`expected dry-run to return 0, got ${rc}`);
  process.exit(1);
}
'

printf 'PASS: archive trace tests\n'
