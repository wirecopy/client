import { open, readFile, readdir, stat } from "node:fs/promises";
import { basename, relative, resolve, sep } from "node:path";

import { UsageError } from "./errors.js";

interface Source {
  absolutePath: string;
  archivePath: string;
}

interface CentralEntry {
  name: Buffer;
  crc: number;
  size: number;
  offset: number;
}

const LOCAL_SIGNATURE = 0x04034b50;
const CENTRAL_SIGNATURE = 0x02014b50;
const END_SIGNATURE = 0x06054b50;
const UTF8_FLAG = 0x0800;
const DOS_DATE_1980_01_01 = 0x0021;

export async function zipFiles(paths: string[], destination: string): Promise<void> {
  const used = new Set<string>();
  const sources: Source[] = [];
  const sorted = [...paths].sort((left, right) => basename(left).localeCompare(basename(right)));
  for (const path of sorted) {
    const info = await stat(path).catch(() => undefined);
    if (!info?.isFile()) {
      throw new UsageError(`Cannot publish unreadable file or directory: ${path}`);
    }
    sources.push({ absolutePath: path, archivePath: uniqueName(basename(path), used) });
  }
  await writeZip(sources, destination);
}

export async function zipSite(directory: string, destination: string): Promise<void> {
  const root = resolve(directory);
  const sources = await collectSiteFiles(root);
  if (!sources.some((source) => source.archivePath === "index.html")) {
    throw new UsageError("The site folder needs an index.html file at its root.");
  }
  await writeZip(sources, destination);
}

async function collectSiteFiles(root: string, current = root): Promise<Source[]> {
  const entries = await readdir(current, { withFileTypes: true });
  const sources: Source[] = [];

  for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
    if (entry.name.startsWith(".")) {
      continue;
    }
    const path = resolve(current, entry.name);
    if (entry.isSymbolicLink()) {
      throw new UsageError("Site folders cannot contain symbolic links.");
    }
    if (entry.isDirectory()) {
      sources.push(...await collectSiteFiles(root, path));
    } else if (entry.isFile()) {
      const archivePath = relative(root, path).split(sep).join("/");
      if (!archivePath || archivePath.split("/").includes("..")) {
        throw new UsageError("The site folder contains an unsafe path.");
      }
      sources.push({ absolutePath: path, archivePath });
    }
  }
  return sources;
}

async function writeZip(sources: Source[], destination: string): Promise<void> {
  if (sources.length > 65_535) {
    throw new UsageError("ZIP archives cannot contain more than 65,535 files.");
  }

  const output = await open(destination, "w", 0o600);
  const entries: CentralEntry[] = [];
  let position = 0;

  try {
    for (const source of sources) {
      const bytes = await readFile(source.absolutePath);
      const name = Buffer.from(source.archivePath, "utf8");
      const crc = crc32(bytes);
      assertZip32(position, bytes.length);

      const header = Buffer.alloc(30);
      header.writeUInt32LE(LOCAL_SIGNATURE, 0);
      header.writeUInt16LE(20, 4);
      header.writeUInt16LE(UTF8_FLAG, 6);
      header.writeUInt16LE(0, 8);
      header.writeUInt16LE(0, 10);
      header.writeUInt16LE(DOS_DATE_1980_01_01, 12);
      header.writeUInt32LE(crc, 14);
      header.writeUInt32LE(bytes.length, 18);
      header.writeUInt32LE(bytes.length, 22);
      header.writeUInt16LE(name.length, 26);
      header.writeUInt16LE(0, 28);

      await output.write(header, 0, header.length, position);
      await output.write(name, 0, name.length, position + header.length);
      await output.write(bytes, 0, bytes.length, position + header.length + name.length);
      entries.push({ name, crc, size: bytes.length, offset: position });
      position += header.length + name.length + bytes.length;
    }

    const centralOffset = position;
    for (const entry of entries) {
      const header = Buffer.alloc(46);
      header.writeUInt32LE(CENTRAL_SIGNATURE, 0);
      header.writeUInt16LE(0x0314, 4);
      header.writeUInt16LE(20, 6);
      header.writeUInt16LE(UTF8_FLAG, 8);
      header.writeUInt16LE(0, 10);
      header.writeUInt16LE(0, 12);
      header.writeUInt16LE(DOS_DATE_1980_01_01, 14);
      header.writeUInt32LE(entry.crc, 16);
      header.writeUInt32LE(entry.size, 20);
      header.writeUInt32LE(entry.size, 24);
      header.writeUInt16LE(entry.name.length, 28);
      header.writeUInt16LE(0, 30);
      header.writeUInt16LE(0, 32);
      header.writeUInt16LE(0, 34);
      header.writeUInt16LE(0, 36);
      header.writeUInt32LE(0x81a40000, 38);
      header.writeUInt32LE(entry.offset, 42);
      await output.write(header, 0, header.length, position);
      await output.write(entry.name, 0, entry.name.length, position + header.length);
      position += header.length + entry.name.length;
    }

    const centralSize = position - centralOffset;
    assertZip32(centralOffset, centralSize);
    const end = Buffer.alloc(22);
    end.writeUInt32LE(END_SIGNATURE, 0);
    end.writeUInt16LE(0, 4);
    end.writeUInt16LE(0, 6);
    end.writeUInt16LE(entries.length, 8);
    end.writeUInt16LE(entries.length, 10);
    end.writeUInt32LE(centralSize, 12);
    end.writeUInt32LE(centralOffset, 16);
    end.writeUInt16LE(0, 20);
    await output.write(end, 0, end.length, position);
  } finally {
    await output.close();
  }
}

function uniqueName(input: string, used: Set<string>): string {
  const clean = input.replaceAll("/", "_").replaceAll("\0", "_");
  if (!used.has(clean)) {
    used.add(clean);
    return clean;
  }
  const dot = clean.lastIndexOf(".");
  const stem = dot > 0 ? clean.slice(0, dot) : clean;
  const extension = dot > 0 ? clean.slice(dot) : "";
  for (let index = 2; ; index += 1) {
    const candidate = `${stem}-${index}${extension}`;
    if (!used.has(candidate)) {
      used.add(candidate);
      return candidate;
    }
  }
}

function assertZip32(...values: number[]): void {
  if (values.some((value) => value > 0xffff_ffff)) {
    throw new UsageError("The archive is too large for the supported ZIP format.");
  }
}

function crc32(bytes: Buffer): number {
  let crc = 0xffff_ffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (crc ^ 0xffff_ffff) >>> 0;
}
