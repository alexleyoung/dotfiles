import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type {
  AutocompleteItem,
  AutocompleteProvider,
  AutocompleteSuggestions,
} from "@earendil-works/pi-tui";
import { readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, resolve } from "node:path";

interface PathToken {
  prefix: string;
  rawPath: string;
  quoted: boolean;
}

function extractPathToken(text: string): PathToken | undefined {
  const quoted = text.match(/(?:^|[\t ])(@"[^"]*)$/)?.[1];
  if (quoted) {
    const rawPath = quoted.slice(2);
    if (rawPath.includes("/") || rawPath.includes("\\")) {
      return { prefix: quoted, rawPath, quoted: true };
    }
  }

  const unquoted = text.match(/(?:^|[\t ])(@[^\s"']*)$/)?.[1];
  if (!unquoted) return undefined;

  const rawPath = unquoted.slice(1);
  if (!rawPath.includes("/") && !rawPath.includes("\\")) return undefined;
  return { prefix: unquoted, rawPath, quoted: false };
}

function splitPath(rawPath: string): { displayBase: string; partial: string } {
  const slash = Math.max(rawPath.lastIndexOf("/"), rawPath.lastIndexOf("\\"));
  return {
    displayBase: rawPath.slice(0, slash + 1),
    partial: rawPath.slice(slash + 1),
  };
}

function resolveSearchDirectory(displayBase: string, cwd: string): string {
  if (displayBase === "~/" || displayBase.startsWith("~/")) {
    return resolve(homedir(), displayBase.slice(2));
  }
  if (displayBase === "~\\" || displayBase.startsWith("~\\")) {
    return resolve(homedir(), displayBase.slice(2));
  }
  return isAbsolute(displayBase) ? resolve(displayBase) : resolve(cwd, displayBase);
}

function completionValue(path: string, quoted: boolean, isDirectory: boolean): string {
  const needsQuote = quoted || /\s/.test(path);
  if (!needsQuote) return `@${path}`;

  // Keep directory quotes open so the next path component can be typed directly.
  return isDirectory ? `@"${path}` : `@"${path}"`;
}

function getPathSuggestions(token: PathToken, cwd: string): AutocompleteItem[] {
  const { displayBase, partial } = splitPath(token.rawPath);
  const searchDirectory = resolveSearchDirectory(displayBase, cwd);
  const lowerPartial = partial.toLocaleLowerCase();

  try {
    return readdirSync(searchDirectory, { withFileTypes: true })
      .flatMap((entry): Array<AutocompleteItem & { isDirectory: boolean }> => {
        if (!entry.name.toLocaleLowerCase().startsWith(lowerPartial)) return [];

        let isDirectory = entry.isDirectory();
        if (!isDirectory && entry.isSymbolicLink()) {
          try {
            isDirectory = statSync(resolve(searchDirectory, entry.name)).isDirectory();
          } catch {
            // Keep broken or inaccessible symlinks as files.
          }
        }

        const displayPath = `${displayBase}${entry.name}${isDirectory ? "/" : ""}`;
        return [{
          value: completionValue(displayPath, token.quoted, isDirectory),
          label: `${entry.name}${isDirectory ? "/" : ""}`,
          description: displayPath,
          isDirectory,
        }];
      })
      .sort((a, b) =>
        a.isDirectory === b.isDirectory
          ? a.label.localeCompare(b.label)
          : a.isDirectory ? -1 : 1,
      )
      .slice(0, 20)
      .map(({ isDirectory: _isDirectory, ...item }) => item);
  } catch {
    return [];
  }
}

function createProvider(current: AutocompleteProvider, cwd: string): AutocompleteProvider {
  return {
    triggerCharacters: ["@", "/"],

    async getSuggestions(lines, cursorLine, cursorCol, options): Promise<AutocompleteSuggestions | null> {
      const beforeCursor = (lines[cursorLine] ?? "").slice(0, cursorCol);
      const token = extractPathToken(beforeCursor);
      if (!token) return current.getSuggestions(lines, cursorLine, cursorCol, options);

      const items = getPathSuggestions(token, cwd);
      return items.length > 0 ? { items, prefix: token.prefix } : null;
    },

    applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
      const beforeCursor = (lines[cursorLine] ?? "").slice(0, cursorCol);
      const token = extractPathToken(beforeCursor);
      if (!token || token.prefix !== prefix) {
        return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
      }

      const currentLine = lines[cursorLine] ?? "";
      const beforePrefix = currentLine.slice(0, cursorCol - prefix.length);
      let afterCursor = currentLine.slice(cursorCol);
      if (item.value.endsWith('"') && afterCursor.startsWith('"')) {
        afterCursor = afterCursor.slice(1);
      }

      const isDirectory = item.label.endsWith("/");
      const suffix = isDirectory ? "" : " ";
      const newLines = [...lines];
      newLines[cursorLine] = `${beforePrefix}${item.value}${suffix}${afterCursor}`;

      return {
        lines: newLines,
        cursorLine,
        cursorCol: beforePrefix.length + item.value.length + suffix.length,
      };
    },

    shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
      return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
    },
  };
}

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.addAutocompleteProvider((current) => createProvider(current, ctx.cwd));
  });
}
