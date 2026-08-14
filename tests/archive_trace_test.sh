#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO_ROOT/scripts"

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

printf 'PASS: archive trace tests\n'
