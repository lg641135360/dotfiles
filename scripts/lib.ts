import { readFileSync, writeFileSync, mkdirSync, statSync } from "node:fs";
import path from "node:path";

export type ParsedArgs = Record<string, string | boolean>;

export function parseArgs(argv: string[]): ParsedArgs {
  const args: ParsedArgs = {};
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith("--")) continue;
    const body = token.slice(2);
    // Support --flag=value syntax.
    const eq = body.indexOf("=");
    if (eq >= 0) {
      const name = body.slice(0, eq);
      const value = body.slice(eq + 1);
      args[name] = value;
      continue;
    }
    const name = body;
    const next = argv[i + 1];
    if (next && !next.startsWith("--")) {
      args[name] = next;
      i++;
    } else {
      args[name] = true;
    }
  }
  return args;
}

export function repoRoot(): string {
  // scripts/ is directly under repo root
  return path.resolve(new URL(".", import.meta.url).pathname, "..");
}

export function readText(filePath: string): string {
  return readFileSync(filePath, "utf8");
}

export function writeText(filePath: string, text: string): void {
  mkdirSync(path.dirname(filePath), { recursive: true });
  writeFileSync(filePath, text, "utf8");
}

export function pathExists(filePath: string): boolean {
  try {
    statSync(filePath);
    return true;
  } catch {
    return false;
  }
}

export function isFile(filePath: string): boolean {
  try {
    return statSync(filePath).isFile();
  } catch {
    return false;
  }
}

export function isDirectory(filePath: string): boolean {
  try {
    return statSync(filePath).isDirectory();
  } catch {
    return false;
  }
}
