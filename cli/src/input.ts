import { mkdtemp, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, extname, join, resolve } from "node:path";

import { UsageError } from "./errors.js";
import { zipFiles, zipSite } from "./zip.js";

export interface PreparedInput {
  path: string;
  filename: string;
  contentType: string;
  byteSize: number;
  notice?: string;
  cleanup(): Promise<void>;
}

export async function prepareFiles(inputs: string[]): Promise<PreparedInput> {
  const paths = inputs.map((input) => resolvePath(input));
  if (paths.length === 1) {
    const path = paths[0]!;
    const info = await stat(path).catch(() => undefined);
    if (!info?.isFile()) {
      throw new UsageError(`Cannot publish unreadable file or directory: ${path}`);
    }
    return {
      path,
      filename: safeFilename(basename(path)),
      contentType: contentTypeFor(path),
      byteSize: info.size,
      cleanup: async () => {},
    };
  }

  const temporaryDirectory = await mkdtemp(join(tmpdir(), "wirecopy-"));
  const output = join(temporaryDirectory, "wirecopy-files.zip");
  await zipFiles(paths, output);
  const info = await stat(output);
  return {
    path: output,
    filename: "wirecopy-files.zip",
    contentType: "application/zip",
    byteSize: info.size,
    cleanup: () => rm(temporaryDirectory, { recursive: true, force: true }),
  };
}

export async function prepareSite(input: string): Promise<PreparedInput> {
  const requestedPath = resolvePath(input);
  let path = requestedPath;
  const info = await stat(path).catch(() => undefined);
  if (info?.isDirectory()) {
    const resolved = await resolveSiteDirectory(path);
    path = resolved.path;
    const temporaryDirectory = await mkdtemp(join(tmpdir(), "wirecopy-site-"));
    const output = join(temporaryDirectory, `${safeFilename(basename(path)) || "site"}.zip`);
    await zipSite(path, output);
    const archiveInfo = await stat(output);
    return {
      path: output,
      filename: basename(output),
      contentType: "application/zip",
      byteSize: archiveInfo.size,
      ...(resolved.notice ? { notice: resolved.notice } : {}),
      cleanup: () => rm(temporaryDirectory, { recursive: true, force: true }),
    };
  }
  if (!info?.isFile()) {
    throw new UsageError("Choose an HTML file, ZIP, or folder containing index.html.");
  }
  if (![".html", ".htm", ".zip"].includes(extname(path).toLowerCase())) {
    throw new UsageError("Site publishing accepts .html, .htm, or .zip inputs.");
  }
  return {
    path,
    filename: safeFilename(basename(path)),
    contentType: contentTypeFor(path),
    byteSize: info.size,
    cleanup: async () => {},
  };
}

async function resolveSiteDirectory(path: string): Promise<{ path: string; notice?: string }> {
  const packageJson = await stat(join(path, "package.json")).catch(() => undefined);
  if (!packageJson?.isFile()) {
    return { path };
  }

  const candidates = ["dist", "build", "out", join(".output", "public")];
  for (const candidate of candidates) {
    const output = join(path, candidate);
    const index = await stat(join(output, "index.html")).catch(() => undefined);
    if (index?.isFile()) {
      return {
        path: output,
        notice: `Using ${candidate.replaceAll("\\", "/")} from ${basename(path)}`,
      };
    }
  }

  throw new UsageError(
    "This looks like application source, not a built site. Run the project build, then pass its output directory (for example dist/ or build/).",
  );
}

function resolvePath(input: string): string {
  if (input === "~") {
    return process.env.HOME ?? input;
  }
  if (input.startsWith("~/") && process.env.HOME) {
    return resolve(process.env.HOME, input.slice(2));
  }
  return resolve(input);
}

function safeFilename(value: string): string {
  return value.replaceAll("/", "_").replaceAll("\0", "_");
}

function contentTypeFor(path: string): string {
  const types: Record<string, string> = {
    ".css": "text/css",
    ".gif": "image/gif",
    ".htm": "text/html",
    ".html": "text/html",
    ".jpeg": "image/jpeg",
    ".jpg": "image/jpeg",
    ".json": "application/json",
    ".md": "text/markdown",
    ".pdf": "application/pdf",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".txt": "text/plain",
    ".webp": "image/webp",
    ".zip": "application/zip",
  };
  return types[extname(path).toLowerCase()] ?? "application/octet-stream";
}
