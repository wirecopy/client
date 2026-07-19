import assert from "node:assert/strict";
import { mkdtemp, mkdir, readFile, stat, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { formatProgressLine } from "../dist/progress.js";

const CLI = fileURLToPath(new URL("../dist/index.js", import.meta.url));

test("prints help without configuration", async () => {
  const result = await run(["--help"]);
  assert.equal(result.code, 0);
  assert.match(result.stdout, /npx|wirecopy site|publish files/i);
});

test("stores configuration with private file permissions", async () => {
  const directory = await mkdtemp(join(tmpdir(), "wirecopy-test-"));
  const result = await run(
    ["configure", "--token", "wc_live_test", "--server", "https://example.test"],
    { WIRECOPY_CONFIG_DIR: directory },
  );
  assert.equal(result.code, 0, result.stderr);
  const path = join(directory, "config.json");
  const config = JSON.parse(await readFile(path, "utf8"));
  assert.equal(config.token, "wc_live_test");
  if (process.platform !== "win32") {
    assert.equal((await stat(path)).mode & 0o777, 0o600);
  }
});

test("refuses to send credentials to a remote plaintext server", async () => {
  const directory = await mkdtemp(join(tmpdir(), "wirecopy-test-"));
  const result = await run(
    ["configure", "--token", "wc_live_test", "--server", "http://example.test"],
    { WIRECOPY_CONFIG_DIR: directory },
  );
  assert.equal(result.code, 78);
  assert.match(result.stderr, /refuses.*plaintext HTTP/i);
});

test("publishes a file through a direct upload grant", async (context) => {
  const directory = await mkdtemp(join(tmpdir(), "wirecopy-test-"));
  const file = join(directory, "report.txt");
  await writeFile(file, "actual artifact");
  let uploaded = "";
  let uploadHeaders;

  const server = createServer(async (request, response) => {
    const url = new URL(request.url, "http://localhost");
    if (url.pathname === "/api/v1/upload_intents" && request.method === "POST") {
      json(response, 201, {
        id: "intent-1",
        state: "uploading",
        filename: "report.txt",
        content_type: "text/plain",
        byte_size: 15,
        expires_at: "2030-01-01T00:00:00Z",
        upload: {
          url: `${origin(server)}/object`,
          method: "PUT",
          headers: { "Content-Type": "text/plain" },
        },
      });
    } else if (url.pathname === "/object" && request.method === "PUT") {
      uploadHeaders = request.headers;
      uploaded = await body(request);
      response.writeHead(200).end();
    } else if (url.pathname === "/api/v1/upload_intents/intent-1/complete") {
      json(response, 200, {
        id: "intent-1",
        state: "available",
        filename: "report.txt",
        content_type: "text/plain",
        byte_size: 15,
        expires_at: "2030-01-01T00:00:00Z",
        link: { url: "https://wirecopy.test/d/result", expires_at: "2030-01-01T00:00:00Z" },
      });
    } else {
      response.writeHead(404).end();
    }
  });
  await listen(server);
  context.after(() => server.close());

  const result = await run(["publish", file], {
    WIRECOPY_TOKEN: "wc_live_test",
    WIRECOPY_SERVER: origin(server),
  });
  assert.equal(result.code, 0, result.stderr);
  assert.equal(result.stdout.trim(), "https://wirecopy.test/d/result");
  assert.equal(uploaded, "actual artifact");
  assert.equal(uploadHeaders["content-length"], "15");
  assert.equal(uploadHeaders["transfer-encoding"], undefined);
});

test("packages and publishes a site folder", async (context) => {
  const directory = await mkdtemp(join(tmpdir(), "wirecopy-test-"));
  const site = join(directory, "dist");
  await mkdir(join(site, "assets"), { recursive: true });
  await writeFile(join(site, "index.html"), "<h1>Wirecopy</h1>");
  await writeFile(join(site, "assets", "app.js"), "console.log('live')");
  let multipart = Buffer.alloc(0);

  const server = createServer(async (request, response) => {
    if (request.url === "/api/v1/sites" && request.method === "POST") {
      multipart = await bodyBuffer(request);
      json(response, 201, {
        id: 42,
        state: "published",
        name: "dist.zip",
        url: "https://s-test.wirecopy.site",
        storage: "managed",
        byte_size: 37,
        file_count: 2,
        expires_at: "2030-01-01T00:00:00Z",
      });
    } else {
      response.writeHead(404).end();
    }
  });
  await listen(server);
  context.after(() => server.close());

  const result = await run(["site", site, "--json"], {
    WIRECOPY_TOKEN: "wc_live_test",
    WIRECOPY_SERVER: origin(server),
  });
  assert.equal(result.code, 0, result.stderr);
  assert.equal(JSON.parse(result.stdout).id, 42);
  assert.match(multipart.toString("latin1"), /site\[mode\].*site/s);
  assert.ok(multipart.includes(Buffer.from("index.html")));
  assert.ok(multipart.includes(Buffer.from("assets/app.js")));
});

test("selects a React project build output and excludes dependencies", async (context) => {
  const directory = await mkdtemp(join(tmpdir(), "wirecopy-test-"));
  const project = join(directory, "react-app");
  await mkdir(join(project, "dist", "assets"), { recursive: true });
  await mkdir(join(project, "node_modules", "package"), { recursive: true });
  await mkdir(join(project, "src"), { recursive: true });
  await writeFile(join(project, "package.json"), '{"scripts":{"build":"vite build"}}');
  await writeFile(join(project, "dist", "index.html"), "<main>Built</main>");
  await writeFile(join(project, "dist", "assets", "app.js"), "console.log('built')");
  await writeFile(join(project, "node_modules", "package", "LICENSE"), "not for publishing");
  await writeFile(join(project, "src", "main.jsx"), "not browser output");
  let multipart = Buffer.alloc(0);

  const server = createServer(async (request, response) => {
    if (request.url === "/api/v1/sites" && request.method === "POST") {
      multipart = await bodyBuffer(request);
      json(response, 201, {
        id: 43,
        state: "published",
        name: "dist.zip",
        url: "https://s-built.wirecopy.site",
        storage: "managed",
        byte_size: 37,
        file_count: 2,
        expires_at: "2030-01-01T00:00:00Z",
      });
    } else {
      response.writeHead(404).end();
    }
  });
  await listen(server);
  context.after(() => server.close());

  const result = await run(["site", project, "--json"], {
    WIRECOPY_TOKEN: "wc_live_test",
    WIRECOPY_SERVER: origin(server),
  });
  assert.equal(result.code, 0, result.stderr);
  assert.match(result.stderr, /Using dist from react-app/);
  assert.ok(multipart.includes(Buffer.from("index.html")));
  assert.ok(multipart.includes(Buffer.from("assets/app.js")));
  assert.ok(!multipart.includes(Buffer.from("node_modules")));
  assert.ok(!multipart.includes(Buffer.from("src/main.jsx")));
});

test("rejects unbuilt application source before upload", async () => {
  const directory = await mkdtemp(join(tmpdir(), "wirecopy-test-"));
  const project = join(directory, "react-app");
  await mkdir(join(project, "src"), { recursive: true });
  await writeFile(join(project, "package.json"), '{"scripts":{"build":"vite build"}}');
  await writeFile(join(project, "index.html"), "<div id='root'></div>");
  await writeFile(join(project, "src", "main.jsx"), "source");

  const result = await run(["site", project], {
    WIRECOPY_TOKEN: "wc_live_test",
    WIRECOPY_SERVER: "http://127.0.0.1:1",
  });
  assert.equal(result.code, 64);
  assert.match(result.stderr, /application source.*Run the project build/s);
});

test("formats terminal upload progress with percentage, bytes, and elapsed time", () => {
  const line = formatProgressLine({ label: "Uploading", sent: 512, total: 1024 }, 1500);
  const plain = line.replaceAll(/\u001b\[[0-9;]*m/g, "");

  assert.equal(plain, "Uploading 50% · 512 B / 1.0 KB · 1.5s");
});

function run(arguments_, environment = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [CLI, ...arguments_], {
      env: { ...process.env, ...environment },
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    child.stdout.setEncoding("utf8").on("data", (chunk) => { stdout += chunk; });
    child.stderr.setEncoding("utf8").on("data", (chunk) => { stderr += chunk; });
    child.on("error", reject);
    child.on("close", (code) => resolve({ code, stdout, stderr }));
  });
}

function listen(server) {
  return new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
}

function origin(server) {
  const address = server.address();
  return `http://127.0.0.1:${address.port}`;
}

function body(request) {
  return bodyBuffer(request).then((value) => value.toString("utf8"));
}

function bodyBuffer(request) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    request.on("data", (chunk) => chunks.push(chunk));
    request.on("end", () => resolve(Buffer.concat(chunks)));
    request.on("error", reject);
  });
}

function json(response, status, value) {
  response.writeHead(status, { "Content-Type": "application/json" });
  response.end(JSON.stringify(value));
}
