# Wirecopy CLI

Publish files and working web artifacts from terminals, coding agents and CI.

```bash
npx wirecopy site ./dist
npx wirecopy publish ./report.pdf
```

Install the `wirecopy` command globally when you use it regularly:

```bash
npm install --global wirecopy
wirecopy configure
wirecopy site ./dist
```

Create a revocable device token on the Devices page at
<https://wirecopy.app/device_tokens>. `wirecopy configure` prompts for it
without echoing the token or placing it in shell history. The token is stored
in a user-only configuration file. For CI, provide `WIRECOPY_TOKEN` through
the environment instead:

```bash
WIRECOPY_TOKEN='wc_live_...' wirecopy site ./dist --json
```

`WIRECOPY_SERVER` overrides the default `https://wirecopy.app` API host.
`WIRECOPY_EXPIRES_IN` sets the default retention in seconds.

When `wirecopy site` receives an application project, it publishes an existing
conventional build output (`dist/`, `build/`, `out/`, or `.output/public`) that
contains `index.html`. It never executes package scripts implicitly. Build an
unbuilt project first, or pass its output directory directly.

## Commands

```text
wirecopy configure [--token wc_live_...] [--server URL] [--expires seconds]
wirecopy logout
wirecopy publish <path> [more paths] [--expires seconds] [--format raw|markdown|html|json]
wirecopy site <index.html|site.zip|folder> [--storage managed|byos] [--expires seconds] [--json]
wirecopy links [--json]
wirecopy links revoke <id>
```

File bytes upload directly to the object-storage grant returned by Wirecopy.
Site folders are packaged locally as deterministic, uncompressed ZIP archives
before publication.

Human-readable progress goes to stderr. Links and JSON results go to stdout so
the commands compose safely with scripts.

## Development

```bash
npm install
npm test
npm pack
```

Requires Node.js 20.11 or newer.
