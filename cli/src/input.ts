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
  const path = resolvePath(input);
  const info = await stat(path).catch(() => undefined);
  if (info?.isDirectory()) {
    const temporaryDirectory = await mkdtemp(join(tmpdir(), "wirecopy-site-"));
    const output = join(temporaryDirectory, `${safeFilename(basename(path)) || "site"}.zip`);
    await zipSite(path, output);
    const archiveInfo = await stat(output);
    return {
      path: output,
      filename: basename(output),
      contentType: "application/zip",
      byteSize: archiveInfo.size,
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
