#!/usr/bin/env node

import { clearConfig, loadConfig, parsePositiveInteger, saveConfig } from "./config.js";
import { ApiError, UsageError, errorMessage, exitCodeFor } from "./errors.js";
import { prepareFiles, prepareSite } from "./input.js";
import { WirecopyApi, waitForAvailable, type ManagedLink } from "./api.js";
import { TerminalProgress } from "./progress.js";

const USAGE = `Wirecopy - publish files and working web artifacts

Usage:
  wirecopy configure [--token wc_live_...] [--server URL] [--expires seconds]
  wirecopy logout
  wirecopy publish <path> [more paths] [--expires seconds] [--format raw|markdown|html|json]
  wirecopy site <index.html|site.zip|folder> [--storage managed|byos] [--expires seconds] [--json]
  wirecopy links [--json]
  wirecopy links revoke <id>

Environment:
  WIRECOPY_TOKEN, WIRECOPY_SERVER, WIRECOPY_EXPIRES_IN, WIRECOPY_CONFIG_FILE`;

interface Options {
  positionals: string[];
  flags: Set<string>;
  values: Map<string, string>;
}

async function main(arguments_: string[]): Promise<void> {
  const [command, ...argumentsAfterCommand] = arguments_;
  if (!command || ["help", "--help", "-h"].includes(command)) {
    console.log(USAGE);
    return;
  }

  switch (command) {
    case "configure":
      await configure(argumentsAfterCommand);
      break;
    case "logout":
      await clearConfig();
      console.log("Removed the stored Wirecopy token.");
      break;
    case "publish":
    case "send":
      await publish(argumentsAfterCommand);
      break;
    case "site":
      await publishSite(argumentsAfterCommand);
      break;
    case "links":
      await links(argumentsAfterCommand);
      break;
    default:
      throw new UsageError(`Unknown command: ${command}`);
  }
}

async function configure(arguments_: string[]): Promise<void> {
  const options = parseOptions(arguments_, ["--token", "--server", "--expires"], []);
  if (options.positionals.length > 0) {
    throw new UsageError("configure does not accept positional arguments.");
  }
  const token = options.values.get("--token");
  const resolvedToken = token ?? process.env.WIRECOPY_TOKEN ?? await readSecret();
  if (!resolvedToken) {
    throw new UsageError(
      "configure requires an interactive terminal, --token wc_live_…, or WIRECOPY_TOKEN.",
    );
  }
  const server = options.values.get("--server");
  const expires = options.values.get("--expires");
  const path = await saveConfig({
    token: resolvedToken,
    ...(server ? { server } : {}),
    ...(expires ? { expiresIn: positiveInteger(expires, "--expires") } : {}),
  });
  console.log(`Configured Wirecopy. Credentials stored in ${path}.`);
}

async function publish(arguments_: string[]): Promise<void> {
  const options = parseOptions(arguments_, ["--expires", "--format"], ["--json"]);
  if (options.positionals.length === 0) {
    throw new UsageError("publish requires one or more file paths.");
  }
  const config = await loadConfig();
  const expiresIn = options.values.has("--expires")
    ? positiveInteger(options.values.get("--expires")!, "--expires")
    : config.expiresIn;
  const format = options.flags.has("--json")
    ? "json"
    : options.values.get("--format") ?? "raw";
  if (!["raw", "markdown", "html", "json"].includes(format)) {
    throw new UsageError("--format must be raw, markdown, html, or json.");
  }

  const input = await prepareFiles(options.positionals);
  const activity = new TerminalProgress();
  try {
    const api = new WirecopyApi(config.server, config.token);
    activity.update("Authorizing");
    const created = await api.createIntent(input, expiresIn);
    if (!created.upload) {
      throw new ApiError("invalid_response", "The Wirecopy service did not return an upload grant.");
    }
    activity.update("Uploading", 0, input.byteSize);
    await api.upload(input, created.upload, (sent, total) => activity.update("Uploading", sent, total));
    activity.update("Safety check");
    const intent = await waitForAvailable(api, await api.completeIntent(created.id));
    activity.done("Link ready");
    const link = {
      url: intent.link!.url,
      filename: input.filename,
      byte_size: input.byteSize,
      expires_at: intent.link!.expires_at,
    };
    console.log(formatLink(link, format));
  } finally {
    activity.clear();
    await input.cleanup();
  }
}

async function publishSite(arguments_: string[]): Promise<void> {
  const options = parseOptions(arguments_, ["--expires", "--storage"], ["--json"]);
  if (options.positionals.length !== 1) {
    throw new UsageError("site requires one HTML file, ZIP, or site folder.");
  }
  const storage = options.values.get("--storage");
  if (storage && !["managed", "byos"].includes(storage)) {
    throw new UsageError("--storage must be managed or byos.");
  }
  const config = await loadConfig();
  const expiresIn = options.values.has("--expires")
    ? positiveInteger(options.values.get("--expires")!, "--expires")
    : config.expiresIn;
  const activity = new TerminalProgress();
  let input: Awaited<ReturnType<typeof prepareSite>> | undefined;
  try {
    activity.update("Preparing site");
    input = await prepareSite(options.positionals[0]!);
    if (input.notice) {
      activity.update(input.notice);
    }
    activity.update("Uploading site", 0, input.byteSize);
    const site = await new WirecopyApi(config.server, config.token).publishSite(
      input,
      expiresIn,
      storage as "managed" | "byos" | undefined,
      (sent, total) => activity.update("Uploading site", sent, total),
    );
    activity.done("Site published");
    console.log(options.flags.has("--json") ? JSON.stringify(site) : site.url);
  } catch (error) {
    throw storageHint(error);
  } finally {
    activity.clear();
    await input?.cleanup();
  }
}

async function links(arguments_: string[]): Promise<void> {
  const config = await loadConfig();
  const api = new WirecopyApi(config.server, config.token);
  if (arguments_[0] === "revoke") {
    if (arguments_.length !== 2 || !/^[1-9]\d*$/.test(arguments_[1]!)) {
      throw new UsageError("links revoke requires a numeric link ID.");
    }
    const id = Number(arguments_[1]);
    await api.revokeLink(id);
    console.log(`Revoked link ${id}.`);
    return;
  }

  const options = parseOptions(arguments_, [], ["--json"]);
  if (options.positionals.length > 0) {
    throw new UsageError(`Unknown links action: ${options.positionals[0]}`);
  }
  const result = await api.links();
  if (options.flags.has("--json")) {
    console.log(JSON.stringify(result));
  } else if (result.length === 0) {
    console.log("No links.");
  } else {
    for (const link of result) {
      console.log(formatLinkRow(link));
    }
  }
}

function parseOptions(arguments_: string[], valueOptions: string[], flagOptions: string[]): Options {
  const positionals: string[] = [];
  const flags = new Set<string>();
  const values = new Map<string, string>();
  for (let index = 0; index < arguments_.length; index += 1) {
    const argument = arguments_[index]!;
    if (valueOptions.includes(argument)) {
      const value = arguments_[index + 1];
      if (!value || value.startsWith("--")) {
        throw new UsageError(`${argument} requires a value.`);
      }
      values.set(argument, value);
      index += 1;
    } else if (flagOptions.includes(argument)) {
      flags.add(argument);
    } else if (argument.startsWith("--")) {
      throw new UsageError(`Unknown option: ${argument}`);
    } else {
      positionals.push(argument);
    }
  }
  return { positionals, flags, values };
}

function positiveInteger(value: string, label: string): number {
  try {
    return parsePositiveInteger(value, label);
  } catch (error) {
    throw new UsageError(errorMessage(error));
  }
}

function formatLink(
  link: { url: string; filename: string; byte_size: number; expires_at: string },
  format: string,
): string {
  switch (format) {
    case "markdown":
      return `[${link.filename.replaceAll("\\", "\\\\").replaceAll("]", "\\]")}](${link.url})`;
    case "html":
      return `<a href="${escapeHtml(link.url)}">${escapeHtml(link.filename)}</a>`;
    case "json":
      return JSON.stringify(link);
    default:
      return link.url;
  }
}

function formatLinkRow(link: ManagedLink): string {
  const available = link.revoked_at === null && new Date(link.expires_at) > new Date();
  return `${link.id}\t${available ? "live" : "ended"}\t${link.filename}\t${link.url}`;
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function storageHint(error: unknown): unknown {
  if (!(error instanceof ApiError)) {
    return error;
  }
  if (error.code === "plan_required") {
    return new ApiError(
      error.code,
      `${error.message}\nHint: your bucket needs a Pro plan. Omit --storage byos to use managed storage.`,
      error.status,
    );
  }
  if (error.code === "byos_unavailable") {
    return new ApiError(
      error.code,
      `${error.message}\nHint: connect and verify a bucket in the web dashboard, or omit --storage byos.`,
      error.status,
    );
  }
  return error;
}

async function readSecret(): Promise<string | undefined> {
  if (!process.stdin.isTTY || !process.stderr.isTTY || !process.stdin.setRawMode) {
    return undefined;
  }
  process.stderr.write("Device token: ");
  process.stdin.setEncoding("utf8");
  process.stdin.setRawMode(true);
  process.stdin.resume();
  let value = "";
  try {
    return await new Promise<string>((resolve, reject) => {
      const finish = (callback: () => void): void => {
        process.stdin.off("data", onData);
        process.stdin.off("error", onError);
        callback();
      };
      const onError = (error: Error): void => finish(() => reject(error));
      const onData = (chunk: string): void => {
        for (const character of chunk) {
          if (character === "\u0003") {
            finish(() => reject(new UsageError("Configuration cancelled.")));
            return;
          }
          if (character === "\r" || character === "\n") {
            finish(() => resolve(value.trim()));
            return;
          }
          if (character === "\u007f" || character === "\b") {
            value = value.slice(0, -1);
          } else {
            value += character;
          }
        }
      };
      process.stdin.on("data", onData);
      process.stdin.on("error", onError);
    });
  } finally {
    process.stdin.setRawMode(false);
    process.stdin.pause();
    process.stderr.write("\n");
  }
}

main(process.argv.slice(2)).catch((error: unknown) => {
  process.stderr.write(`wirecopy: ${errorMessage(error)}\n`);
  if (error instanceof UsageError) {
    process.stderr.write("Run 'wirecopy --help' for usage.\n");
  }
  process.exitCode = exitCodeFor(error);
});
