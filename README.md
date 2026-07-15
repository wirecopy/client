# Clipboard to Link

> Working name. The product name and public brand have not been selected.

Clipboard to Link is a product research repository for a developer-focused
macOS utility that turns copied images and files into controlled share links.

The intended default workflow is deliberately small:

```text
Copy an image or file
        ↓
Press one global shortcut
        ↓
Publish through managed cloud or user-owned S3
        ↓
Replace the clipboard with a link
        ↓
Paste anywhere
```

The current thesis is not “another screenshot uploader.” It is a programmable
publishing primitive for terminals, coding agents, GitHub, Markdown, chat,
email, Finder, Shortcuts, Raycast and any application that accepts a URL.

## Current position

- Managed cloud provides a zero-configuration default.
- Bring-your-own S3 provides ownership, portability and custom infrastructure.
- The normal path has no shelf, modal or file picker.
- Privacy, expiration and revocation are product defaults.
- The Mac app, CLI, API and integrations share one publishing model.

Competition is strong. A generic “upload and copy link” utility is not enough.
The project should proceed only if it can be materially faster, more private
and more programmable than established Mac sharing tools.

## Research map

| Document | Purpose |
| --- | --- |
| [Product thesis](docs/product-thesis.md) | Defines the user, problem, positioning and boundaries. |
| [Competitive landscape](docs/competitive-landscape.md) | Maps direct and adjacent competitors and the market implications. |
| [Differentiation](docs/differentiation.md) | Identifies the wedge and features that could make the product stand out. |
| [macOS experience](docs/macos-experience.md) | Specifies clipboard, hotkey, Finder, Share menu and file behavior. |
| [Architecture](docs/architecture.md) | Describes the native client, managed backend, uploads and links. |
| [Managed cloud](docs/managed-cloud.md) | Defines hosted storage, lifecycle, quotas and operating model. |
| [Security and abuse](docs/security-and-abuse.md) | Covers trust boundaries and public-hosting responsibilities. |
| [Business model](docs/business-model.md) | Captures pricing hypotheses and sustainable usage metrics. |
| [Validation plan](docs/validation-plan.md) | Defines tests that must pass before building the full SaaS. |
| [Research sources](docs/research-sources.md) | Records primary sources and time-sensitive observations. |
| [Decisions](docs/decisions/README.md) | Preserves accepted product and architecture decisions. |

## Status

Research and product definition. No application or hosted service has been
implemented yet.
