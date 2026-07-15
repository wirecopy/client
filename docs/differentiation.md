# Differentiation strategy

## The wedge

The product should own one compact behavior:

> Copy an asset, invoke one publishing command, and paste the right kind of
> controlled link into the tool already in focus.

The differentiation comes from the whole contract—input, policy, destination,
output and automation—not one storage provider or isolated feature.

## Product pillars

### 1. One universal publishing command

The same command accepts a clipboard image, copied Finder file, multiple files
or an explicit CLI path. It applies a remembered policy and returns a usable
result without opening a workspace.

This is distinct from leading with capture editing, a shelf or a cloud library.

### 2. Output for the next tool

Users can choose or temporarily override the output:

- raw URL;
- Markdown image: `![alt](url)`;
- Markdown link: `[name](url)`;
- HTML link or image;
- JSON on the CLI for automation.

GitHub, terminals, coding agents, Slack and email should feel like native
destinations even though the product only publishes a link.

### 3. Control without ceremony

Named policy presets make security understandable:

- **Quick:** short retention, direct URL, no prompt;
- **Work:** longer retention and account history;
- **Sensitive:** password or client-side encrypted mode when available;
- **Permanent:** user-owned storage with no automatic deletion.

The UI should show what will happen, not expose raw storage vocabulary on every
upload.

### 4. Hosted convenience without lock-in

Managed cloud works immediately. S3-compatible bring-your-own storage uses the
same interaction and can be selected globally or by preset. Exportable history
and predictable object keys reduce lock-in.

### 5. A real developer surface

The CLI is not a wrapper around UI automation. It uses the same publishing
model and returns stable machine-readable results. Shortcuts, Finder, Raycast,
Alfred, Herdr and editor integrations can call that contract.

## Standout feature candidates

These are hypotheses to validate, not a launch checklist.

| Candidate | User value | Cost or risk | Priority hypothesis |
| --- | --- | --- | --- |
| Global shortcut with conflict detection | Fast path that survives first setup | macOS permissions and reserved shortcuts | Must have |
| Clipboard/Finder multi-format input | One learned command across daily work | Many pasteboard edge cases | Must have, narrow matrix first |
| Raw/Markdown/HTML output | Removes manual formatting | Low complexity if modeled early | Must have |
| CLI with JSON output | Enables remote and scripted use | Versioned contract required | Must have for the wedge |
| Managed cloud and BYOS | Immediate value plus ownership | Two operational paths | Core, staged delivery acceptable |
| Expiring/revocable links | Makes public sharing safer | Redirect service and metadata required | Managed-cloud default |
| One-use links | Useful for sensitive handoff | Race conditions and confusing retries | Experiment |
| Client-side encryption | Provider cannot read content | Preview, scanning, recovery and UX tradeoffs | Research before promise |
| Multi-file landing page or ZIP | Shares a selection coherently | Packaging, limits and preview security | Early follow-up |
| Optional auto-insert | Eliminates final paste step | Accessibility permission and surprise risk | Opt-in experiment |
| Custom domains | Professional links and trust | DNS/support burden | Paid follow-up |
| Link health and revocation from CLI | Developer control | Metadata consistency | Differentiating follow-up |

## What not to build first

- screenshot annotation and recording;
- a rich asset gallery;
- team comments or asynchronous video messaging;
- public profiles and discovery;
- many storage-provider-specific SDKs;
- previews for every document format;
- a Windows client before the Mac workflow proves retention.

The first release should integrate with the user's existing capture and work
tools rather than compete with all of them.

## Defensibility

No single feature here is a moat. The plausible compounding advantages are:

1. a reliable compatibility layer across macOS pasteboard and Finder types;
2. a stable publishing contract reused by native and developer integrations;
3. trusted lifecycle and privacy behavior;
4. habit—the shortcut becomes part of daily work;
5. a growing catalog of output adapters and workflow integrations;
6. efficient managed-hosting operations and abuse controls.

The brand should emphasize speed and control. It should not imply the team
invented remote image transfer; native and competing solutions already cover
parts of the problem.

## Positioning tests

Test these messages before selecting a product name:

1. “Copy anything. Press one shortcut. Paste a controlled link anywhere.”
2. “The universal share shortcut for developers.”
3. “Turn clipboard files into expiring links—from the Mac app or CLI.”
4. “Managed sharing when you want it; your S3 when you do not.”

Measure whether a developer can accurately explain the product after seeing
only the message and a ten-second demonstration.
