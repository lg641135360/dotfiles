/**
 * archive_trace.ts — 将 logs/trace.md 中超过保留数量的旧条目按月归档到 logs/trace-archive/。
 *
 * 用法：
 *   npx tsx scripts/archive_trace.ts              # 执行归档
 *   npx tsx scripts/archive_trace.ts --dry-run     # 只预览，不写文件
 *   npx tsx scripts/archive_trace.ts --keep 10     # 保留最近 10 条（默认 5）
 */

import { mkdirSync } from "node:fs";
import path from "node:path";
import { parseArgs, readText, repoRoot, writeText, isFile } from "./lib.js";

// 匹配 "## YYYY-MM-DD" 开头的条目标题，可选接标题文字
const ENTRY_RE = /^## (\d{4})-(\d{2})-(\d{2})(?:[\s—\-].*)?$/gm;

export function splitEntries(text: string): string[] {
  const matches = [...text.matchAll(ENTRY_RE)];
  return matches.map((match, index) => {
    const start = match.index ?? 0;
    const end = index + 1 < matches.length ? matches[index + 1].index ?? text.length : text.length;
    return text.slice(start, end).trimEnd() + "\n";
  });
}

export function entryMonth(entry: string): string {
  const match = [...entry.matchAll(ENTRY_RE)][0];
  if (!match) throw new Error(`Entry has no date heading: ${entry.slice(0, 80)}`);
  return `${match[1]}-${match[2]}`;
}

function archiveHeader(month: string): string {
  return `# Trace Archive ${month}\n\n> 本文件为按月归档的历史 trace。默认任务不读取本文件；只有用户明确要求或任务依赖历史背景时才按需查看。\n\n`;
}

export function main(argv = process.argv.slice(2)): number {
  const args = parseArgs(argv);
  const keep = Number(args.keep ?? 5);
  const root = repoRoot();
  const tracePath = path.join(root, "logs", "trace.md");
  const archiveDir = path.join(root, "logs", "trace-archive");

  if (!isFile(tracePath)) {
    console.error(`Trace file not found: ${tracePath}`);
    return 1;
  }

  const text = readText(tracePath);

  // Split: everything before the first "## YYYY-MM-DD" is the header
  const firstEntryMatch = [...text.matchAll(ENTRY_RE)][0];
  if (!firstEntryMatch) {
    console.log("No dated entries found, nothing to archive.");
    return 0;
  }

  const headerEnd = firstEntryMatch.index ?? 0;
  const header = text.slice(0, headerEnd).trimEnd();
  const entriesBody = text.slice(headerEnd);
  const entries = splitEntries(entriesBody);

  if (entries.length <= keep) {
    console.log(`No archive needed: entries=${entries.length}, keep=${keep}`);
    return 0;
  }

  const keepEntries = entries.slice(0, keep);
  const archiveEntries = entries.slice(keep);

  // Group archive entries by month
  const byMonth = new Map<string, string[]>();
  for (const entry of archiveEntries) {
    const month = entryMonth(entry);
    const list = byMonth.get(month) ?? [];
    list.push(entry);
    byMonth.set(month, list);
  }

  console.log(`Keep ${keepEntries.length} entries, archive ${archiveEntries.length} entries`);
  for (const [month, monthEntries] of [...byMonth.entries()].sort()) {
    console.log(`  - ${month}: ${monthEntries.length} entries`);
  }

  if (args["dry-run"]) return 0;

  // Write archived entries to monthly files
  mkdirSync(archiveDir, { recursive: true });
  for (const [month, monthEntries] of [...byMonth.entries()].sort()) {
    const archivePath = path.join(archiveDir, `${month}.md`);
    let existing = "";
    try {
      existing = readText(archivePath);
    } catch {
      existing = archiveHeader(month);
    }
    for (const entry of monthEntries) {
      const firstLine = entry.split(/\r?\n/)[0];
      if (!existing.includes(firstLine)) {
        existing = existing.trimEnd() + "\n\n" + entry.trim() + "\n";
      }
    }
    writeText(archivePath, existing);
  }

  // Rewrite trace.md with only kept entries
  const newBody = keepEntries.map((e) => e.trim()).join("\n\n").trim();
  writeText(tracePath, header + "\n\n" + newBody + "\n");

  console.log("Archive complete.");
  return 0;
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  process.exit(main());
}
