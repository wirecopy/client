import { chmod, mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { isIP } from "node:net";

import { ConfigurationError } from "./errors.js";

export interface WirecopyConfig {
  server: string;
  token: string;
  expiresIn: number;
}

interface StoredConfig {
  server?: string;
  token?: string;
  expiresIn?: number;
}

const DEFAULT_SERVER = "https://wirecopy.app";
const DEFAULT_EXPIRES_IN = 86_400;

export function configPath(environment = process.env): string {
  if (environment.WIRECOPY_CONFIG_FILE) {
    return environment.WIRECOPY_CONFIG_FILE;
  }
  if (environment.WIRECOPY_CONFIG_DIR) {
    return join(environment.WIRECOPY_CONFIG_DIR, "config.json");
  }
  if (process.platform === "win32" && environment.APPDATA) {
    return join(environment.APPDATA, "Wirecopy", "config.json");
  }
  return join(environment.XDG_CONFIG_HOME ?? join(homedir(), ".config"), "wirecopy", "config.json");
}

export async function readStoredConfig(path = configPath()): Promise<StoredConfig> {
  try {
    return JSON.parse(await readFile(path, "utf8")) as StoredConfig;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return {};
    }
    throw new ConfigurationError(`Could not read Wirecopy configuration at ${path}.`);
  }
}

export async function loadConfig(environment = process.env): Promise<WirecopyConfig> {
  const stored = await readStoredConfig(configPath(environment));
  const server = environment.WIRECOPY_SERVER ?? stored.server ?? DEFAULT_SERVER;
  const token = environment.WIRECOPY_TOKEN ?? stored.token;
  const expiresIn = parsePositiveInteger(
    environment.WIRECOPY_EXPIRES_IN ?? stored.expiresIn ?? DEFAULT_EXPIRES_IN,
    "WIRECOPY_EXPIRES_IN",
  );

  if (!token) {
    throw new ConfigurationError(
      "No device token configured. Run 'wirecopy configure --token wc_live_…' or set WIRECOPY_TOKEN.",
    );
  }

  validateServer(server);
  return { server, token, expiresIn };
}

export async function saveConfig(input: {
  token: string;
  server?: string;
  expiresIn?: number;
}): Promise<string> {
  const path = configPath();
  const existing = await readStoredConfig(path);
  const config: StoredConfig = {
    server: input.server ?? existing.server ?? DEFAULT_SERVER,
    token: input.token,
    expiresIn: input.expiresIn ?? existing.expiresIn ?? DEFAULT_EXPIRES_IN,
  };
  validateServer(config.server!);

  await mkdir(dirname(path), { recursive: true, mode: 0o700 });
  const temporaryPath = `${path}.${process.pid}.tmp`;
  await writeFile(temporaryPath, `${JSON.stringify(config, null, 2)}\n`, { mode: 0o600 });
  await chmod(temporaryPath, 0o600);
  await rename(temporaryPath, path);
  return path;
}

export async function clearConfig(): Promise<void> {
  await rm(configPath(), { force: true });
}

export function parsePositiveInteger(value: string | number, label: string): number {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isSafeInteger(parsed) || parsed <= 0) {
    throw new ConfigurationError(`${label} must be a positive integer.`);
  }
  return parsed;
}

function validateServer(value: string): void {
  try {
    const url = new URL(value);
    if (!["http:", "https:"].includes(url.protocol)) {
      throw new Error();
    }
    if (url.username || url.password) {
      throw new Error();
    }
    if (url.protocol === "http:" && !isLoopback(url.hostname)) {
      throw new ConfigurationError(
        "Wirecopy refuses to send a device token over plaintext HTTP. Use HTTPS or a loopback development server.",
      );
    }
  } catch {
    if (value.startsWith("http://")) {
      throw new ConfigurationError(
        "Wirecopy refuses to send a device token over plaintext HTTP. Use HTTPS or a loopback development server.",
      );
    }
    throw new ConfigurationError(`Invalid Wirecopy server URL: ${value}`);
  }
}

export function isLoopback(hostname: string): boolean {
  const normalized = hostname.replace(/^\[|\]$/g, "").toLowerCase();
  if (normalized === "localhost" || normalized === "::1") {
    return true;
  }
  return isIP(normalized) === 4 && normalized.startsWith("127.");
}
