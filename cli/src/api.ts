import { createReadStream } from "node:fs";
import { appendFile, mkdtemp, open, rm, stat } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";
import { Readable } from "node:stream";

import { isLoopback } from "./config.js";
import { ApiError } from "./errors.js";
import type { PreparedInput } from "./input.js";

export interface UploadGrant {
  url: string;
  method: string;
  headers: Record<string, string>;
}

export interface UploadIntent {
  id: string;
  state: string;
  filename: string;
  content_type: string;
  byte_size: number;
  expires_at: string;
  error?: { code: string; message?: string } | null;
  link?: { url: string; expires_at: string } | null;
  upload?: UploadGrant | null;
}

export interface ManagedLink {
  id: number;
  url: string;
  filename: string;
  byte_size: number;
  content_type: string;
  access_count: number;
  last_accessed_at: string | null;
  expires_at: string;
  revoked_at: string | null;
  created_at: string;
}

export interface PublishedSite {
  id: number;
  state: string;
  name: string;
  url: string;
  storage: "managed" | "byos";
  byte_size: number;
  file_count: number;
  expires_at: string;
}

interface StreamRequestInit extends RequestInit {
  duplex: "half";
}

export class WirecopyApi {
  constructor(
    private readonly server: string,
    private readonly token: string,
  ) {}

  async createIntent(input: PreparedInput, expiresIn: number): Promise<UploadIntent> {
    return this.request<UploadIntent>("/api/v1/upload_intents", {
      method: "POST",
      body: JSON.stringify({
        upload: {
          mode: "file",
          filename: input.filename,
          content_type: input.contentType,
          byte_size: input.byteSize,
          expires_in: expiresIn,
        },
      }),
    });
  }

  async upload(input: PreparedInput, grant: UploadGrant): Promise<void> {
    validateUploadGrant(grant);
    const response = await networkRequest(
      grant.url,
      {
        method: grant.method,
        headers: grant.headers,
        body: Readable.toWeb(createReadStream(input.path)),
        duplex: "half",
        redirect: "error",
        signal: AbortSignal.timeout(10 * 60 * 1000),
      } as StreamRequestInit,
      "Object storage upload failed.",
    );
    if (!response.ok) {
      throw new ApiError(
        "upload_rejected",
        `Object storage rejected the upload (HTTP ${response.status}).`,
        response.status,
      );
    }
  }

  async completeIntent(id: string): Promise<UploadIntent> {
    return this.request<UploadIntent>(`/api/v1/upload_intents/${encodeURIComponent(id)}/complete`, {
      method: "POST",
      body: "{}",
    });
  }

  async intent(id: string): Promise<UploadIntent> {
    return this.request<UploadIntent>(`/api/v1/upload_intents/${encodeURIComponent(id)}`);
  }

  async links(): Promise<ManagedLink[]> {
    const response = await this.request<{ links: ManagedLink[] }>("/api/v1/links");
    return response.links;
  }

  async revokeLink(id: number): Promise<void> {
    await this.request<void>(`/api/v1/links/${id}`, { method: "DELETE" });
  }

  async publishSite(
    input: PreparedInput,
    expiresIn: number,
    storage?: "managed" | "byos",
  ): Promise<PublishedSite> {
    const boundary = `wirecopy-${crypto.randomUUID()}`;
    const temporaryDirectory = await mkdtemp(join(tmpdir(), "wirecopy-request-"));
    const bodyPath = join(temporaryDirectory, "multipart");
    try {
      await appendFile(bodyPath, part(boundary, "site[mode]", "site"));
      await appendFile(bodyPath, part(boundary, "site[expires_in]", String(expiresIn)));
      if (storage) {
        await appendFile(bodyPath, part(boundary, "site[storage]", storage));
      }
      await appendFile(
        bodyPath,
        `--${boundary}\r\nContent-Disposition: form-data; name="site[archive]"; filename="${escapeFilename(input.filename)}"\r\nContent-Type: ${input.contentType}\r\n\r\n`,
      );
      const output = await open(bodyPath, "a");
      try {
        for await (const chunk of createReadStream(input.path)) {
          await output.write(chunk as Buffer);
        }
      } finally {
        await output.close();
      }
      await appendFile(bodyPath, `\r\n--${boundary}--\r\n`);
      const size = (await stat(bodyPath)).size;
      return await this.request<PublishedSite>("/api/v1/sites", {
        method: "POST",
        headers: {
          "Content-Type": `multipart/form-data; boundary=${boundary}`,
          "Content-Length": String(size),
        },
        body: Readable.toWeb(createReadStream(bodyPath)),
        duplex: "half",
      } as StreamRequestInit);
    } finally {
      await rm(temporaryDirectory, { recursive: true, force: true });
    }
  }

  private async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    const headers = new Headers(init.headers);
    headers.set("Accept", "application/json");
    headers.set("Authorization", `Bearer ${this.token}`);
    if (typeof init.body === "string" && !headers.has("Content-Type")) {
      headers.set("Content-Type", "application/json");
    }

    const response = await networkRequest(
      new URL(path, this.server),
      {
        ...init,
        headers,
        redirect: "error",
        signal: init.signal ?? AbortSignal.timeout(path === "/api/v1/sites" ? 10 * 60 * 1000 : 30_000),
      },
      "Could not reach the Wirecopy service.",
    );
    if (response.status === 204) {
      return undefined as T;
    }
    const body = await response.text();
    if (!response.ok) {
      const detail = parseError(body);
      throw new ApiError(
        detail.code ?? `http_${response.status}`,
        detail.message ?? `Wirecopy request failed (HTTP ${response.status}).`,
        response.status,
      );
    }
    try {
      return JSON.parse(body) as T;
    } catch {
      throw new ApiError("invalid_response", "The Wirecopy service returned an invalid response.");
    }
  }
}

export async function waitForAvailable(
  api: WirecopyApi,
  initial: UploadIntent,
): Promise<UploadIntent> {
  let intent = initial;
  if (intent.state === "quarantined") {
    for (let attempt = 0; attempt < 30; attempt += 1) {
      await new Promise((resolve) => setTimeout(resolve, 500 + attempt * 50));
      intent = await api.intent(intent.id);
      if (["available", "rejected"].includes(intent.state)) {
        break;
      }
    }
  }
  if (intent.state !== "available" || !intent.link) {
    if (intent.error) {
      throw new ApiError(intent.error.code, intent.error.message ?? intent.error.code);
    }
    throw new ApiError(
      "scan_timeout",
      "The safety check is taking longer than expected. The file remains quarantined.",
    );
  }
  return intent;
}

function part(boundary: string, name: string, value: string): string {
  return `--${boundary}\r\nContent-Disposition: form-data; name="${name}"\r\n\r\n${value}\r\n`;
}

function escapeFilename(value: string): string {
  return basename(value).replaceAll('"', "_").replaceAll("\r", "_").replaceAll("\n", "_");
}

function parseError(body: string): { code?: string; message?: string } {
  try {
    const parsed = JSON.parse(body) as { error?: { code?: string; message?: string } };
    return parsed.error ?? {};
  } catch {
    return {};
  }
}

function validateUploadGrant(grant: UploadGrant): void {
  if (grant.method.toUpperCase() !== "PUT") {
    throw new ApiError("invalid_upload_grant", "The Wirecopy service returned an unsupported upload method.");
  }
  let url: URL;
  try {
    url = new URL(grant.url);
  } catch {
    throw new ApiError("invalid_upload_grant", "The Wirecopy service returned an invalid upload URL.");
  }
  if (url.protocol !== "https:" && !(url.protocol === "http:" && isLoopback(url.hostname))) {
    throw new ApiError(
      "invalid_upload_grant",
      "Wirecopy refused an insecure object-storage upload URL.",
    );
  }
}

async function networkRequest(
  input: string | URL,
  init: RequestInit,
  failureMessage: string,
): Promise<Response> {
  try {
    return await fetch(input, init);
  } catch (error) {
    const reason = error instanceof Error && error.name === "TimeoutError"
      ? " The request timed out."
      : "";
    throw new ApiError("network_error", `${failureMessage}${reason}`);
  }
}
