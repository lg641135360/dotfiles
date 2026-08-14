/**
 * archive_trace.ts — 将 logs/trace.md 中超过保留数量的旧条目按月归档到 logs/trace-archive/。
 *
 * 归档单位是「一条变更摘要」（即 trace.md 中的一条记录），而非 `## YYYY-MM-DD` 日期标题：
 * 单日往往会产生多个变更摘要，按日期计数会让单日多变更的情况无法被归档，导致
 * trace.md 行数膨胀。
 *
 * trace.md 有两种合法格式（脚本都支持）：
 *   1. `## YYYY-MM-DD` 裸日期 + 一个或多个 `### 子条目标题` 子条目
 *   2. `## YYYY-MM-DD — 变更标题` 日期带标题，日期下直接是正文（视为单条子条目）
 *
 * 归档时按子条目所属的日期确定归档月份；归档与重写 trace.md 时均保留原始格式。
 *
 * 用法：
 *   npx tsx scripts/archive_trace.ts              # 执行归档
 *   npx tsx scripts/archive_trace.ts --dry-run     # 只预览，不写文件
 *   npx tsx scripts/archive_trace.ts --keep 10     # 保留最近 10 条子条目（默认 5）
 */

import { mkdirSync } from "node:fs";
import path from "node:path";
import { parseArgs, readText, repoRoot, writeText, isFile } from "./lib.js";

// 匹配 "## YYYY-MM-DD" 日期标题，可带可选附加标题（"— 附加说明" 或 "- 附加说明"）
const DAY_RE = /^## (\d{4})-(\d{2})-(\d{2})(?:[\s—\-].*)?$/gm;

interface SubEntry {
  rawText: string; // 该子条目在原文档中的完整文本（含 ## 或 ### 标题及正文），归档/重写时原样使用
  heading: string; // 用于 dry-run 显示：格式 1 是 "### 子标题"，格式 2 是 "## YYYY-MM-DD — 标题"
  day: string; // YYYY-MM-DD，所属 ## 日期标题
  month: string; // YYYY-MM
}

/**
 * 把 trace.md 拆分为 header（维护规则）与按子条目为单位的列表。
 *
 * 支持两种格式：
 *   - 格式 1：`## YYYY-MM-DD` + 一个或多个 `### 子条目标题`，每个 ### 是一条子条目
 *   - 格式 2：`## YYYY-MM-DD — 变更标题` + 正文，整段是一条子条目
 *
 * 子条目的 rawText 保留原始格式：格式 1 是 `### 子标题\n\n正文`，
 * 格式 2 是 `## YYYY-MM-DD — 标题\n\n正文`（重写 trace.md 时按日期分组避免重复 ## 行）。
 */
export function splitEntries(text: string): { header: string; subEntries: SubEntry[] } {
  const firstDayMatch = [...text.matchAll(DAY_RE)][0];
  if (!firstDayMatch) {
    return { header: text, subEntries: [] };
  }
  const header = text.slice(0, firstDayMatch.index ?? 0).trimEnd();

  const dayMatches = [...text.matchAll(DAY_RE)];
  const subEntries: SubEntry[] = [];

  for (let i = 0; i < dayMatches.length; i++) {
    const dayStart = dayMatches[i].index ?? 0;
    const dayEnd = i + 1 < dayMatches.length ? dayMatches[i + 1].index ?? text.length : text.length;
    const dayBlock = text.slice(dayStart, dayEnd);
    const m = dayMatches[i];
    const day = `${m[1]}-${m[2]}-${m[3]}`;
    const month = `${m[1]}-${m[2]}`;
    const fullTitleLine = dayBlock.split(/\r?\n/, 1)[0]; // 完整 ## 行
    const restLines = dayBlock.split(/\r?\n/).slice(1);
    const attachedTitle = m[0]?.replace(/^## \d{4}-\d{2}-\d{2}\s*/, "").replace(/^[—\-]\s*/, "").trim() ?? "";

    if (attachedTitle) {
      // 格式 2：## YYYY-MM-DD — 变更标题 + 正文，整段是一条子条目
      const body = restLines.join("\n").trim();
      if (body) {
        subEntries.push({
          rawText: `${fullTitleLine}\n\n${body}\n`,
          heading: fullTitleLine,
          day,
          month,
        });
      }
    } else {
      // 格式 1：## YYYY-MM-DD + 一个或多个 ### 子条目
      let currentSub: string[] | null = null;
      for (const line of restLines) {
        if (/^### .+/.test(line)) {
          if (currentSub !== null) {
            subEntries.push({
              rawText: currentSub.join("\n").trimEnd() + "\n",
              heading: currentSub[0],
              day,
              month,
            });
          }
          currentSub = [line];
        } else if (currentSub !== null) {
          currentSub.push(line);
        }
      }
      if (currentSub !== null) {
        subEntries.push({
          rawText: currentSub.join("\n").trimEnd() + "\n",
          heading: currentSub[0],
          day,
          month,
        });
      }
    }
  }

  return { header, subEntries };
}

export function entryMonth(entry: SubEntry): string {
  return entry.month;
}

/**
 * 日期新的条目优先；同一天没有更细粒度时间戳时，以文档中后出现的条目为新。
 * trace.md 采用追加写入，因此同日必须反转原始顺序，不能依赖稳定排序保留最早项。
 */
export function sortEntriesNewestFirst(entries: SubEntry[]): SubEntry[] {
  return entries
    .map((entry, index) => ({ entry, index }))
    .sort((a, b) => b.entry.day.localeCompare(a.entry.day) || b.index - a.index)
    .map(({ entry }) => entry);
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
  const { header, subEntries } = splitEntries(text);

  if (subEntries.length === 0) {
    console.log("No dated sub-entries found, nothing to archive.");
    return 0;
  }

  if (subEntries.length <= keep) {
    console.log(`No archive needed: entries=${subEntries.length}, keep=${keep}`);
    return 0;
  }

  // 按日期降序排序（最新在前），保留前 keep 条，其余归档。
  // trace.md 文档内的 ## YYYY-MM-DD 标题顺序未必是时间序，必须显式按日期排序。
  const sorted = sortEntriesNewestFirst(subEntries);
  const keepEntries = sorted.slice(0, keep);
  const archiveEntries = sorted.slice(keep);

  // 归档条目按月份分组
  const byMonth = new Map<string, SubEntry[]>();
  for (const entry of archiveEntries) {
    const list = byMonth.get(entry.month) ?? [];
    list.push(entry);
    byMonth.set(entry.month, list);
  }

  console.log(`Keep ${keepEntries.length} sub-entries, archive ${archiveEntries.length} sub-entries`);
  for (const [month, monthEntries] of [...byMonth.entries()].sort()) {
    console.log(`  - ${month}: ${monthEntries.length} sub-entries`);
  }
  if (args["dry-run"]) {
    console.log("  Archive sub-entries:");
    for (const entry of archiveEntries) {
      console.log(`    [${entry.day}] ${entry.heading}`);
    }
    console.log("  Keep sub-entries:");
    for (const entry of keepEntries) {
      console.log(`    [${entry.day}] ${entry.heading}`);
    }
    return 0;
  }

  // 把归档子条目写入对应月份的归档文件（原样保留 rawText，避免格式漂移）
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
      const firstLine = entry.rawText.split(/\r?\n/)[0];
      if (!existing.includes(firstLine)) {
        existing = existing.trimEnd() + "\n\n" + entry.rawText.trim() + "\n";
      }
    }
    writeText(archivePath, existing);
  }

  // 重写 trace.md：header + 按日期降序分组的保留子条目。
  // - 格式 2（## YYYY-MM-DD — 标题）的子条目，rawText 已含 ## 行，直接写入；
  //   同一天多条格式 2 会自动合并（极少见，但保留兼容）。
  // - 格式 1（### 子条目）的子条目，需在 day 变化时插入裸 `## YYYY-MM-DD` 行作为视觉分组。
  const out: string[] = [header.trimEnd(), ""];
  let prevDay: string | null = null;
  for (const entry of keepEntries) {
    const isFormat2 = entry.rawText.startsWith("## ");
    if (!isFormat2 && entry.day !== prevDay) {
      // 格式 1：插入裸 ## YYYY-MM-DD 行作为视觉分组
      out.push(`## ${entry.day}`);
      prevDay = entry.day;
    }
    // 每条子条目前后都加空行，避免条目间紧贴
    out.push("");
    out.push(entry.rawText.trim());
    out.push("");
  }
  writeText(tracePath, out.join("\n").trim() + "\n");

  console.log("Archive complete.");
  return 0;
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  process.exit(main());
}
