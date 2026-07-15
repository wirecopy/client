# Product thesis

## One-sentence position

Clipboard to Link is a developer-first macOS publishing utility: copy an image
or file, press one shortcut, and paste a controlled link into any application.

The working name describes the job, not the eventual brand.

## The problem

Modern developer work crosses local and remote boundaries. A screenshot may be
on a Mac while the coding agent, shell or development environment that needs it
is running on a remote machine. Native image paste can solve the local case, but
it does not provide a durable, portable URL for remote terminals, issue
trackers, Markdown, chat or email.

The recurring workaround has too many context switches:

1. Save or export the asset.
2. Choose an uploader or storage console.
3. Upload it.
4. find the correct sharing option.
5. Copy the URL.
6. Return to the original application.
7. Paste it in the expected format.

The product collapses that sequence into one publishing command.

## Primary users

The initial audience is developers and technical creators who:

- work in terminals, coding agents or remote development boxes;
- frequently add screenshots and files to GitHub, Markdown, chat and email;
- want a global shortcut rather than a separate sharing workspace;
- care about expiration, revocation and knowing where their files live;
- may prefer user-owned S3-compatible storage but still value a hosted default.

The initial persona is intentionally narrower than “everyone who shares a
file.” The workflow can later serve designers, support engineers and writers
without weakening the developer-first product decisions.

## Core job

> When I have an image or file ready to share, publish it with the right access
> policy and give me a paste-ready link without interrupting my current work.

The product is successful when the user thinks about the destination, not the
upload mechanics.

## Product principles

### Invisible by default

The normal path is `copy → shortcut → paste`. Configuration, history and
management exist, but do not sit in that path.

### Controlled links, not merely public files

Expiration, revocation, deletion and destination choice are part of publishing.
A link should have an understandable lifecycle.

### One workflow, two storage modes

Managed cloud is the fastest onboarding path. Bring-your-own storage is the
ownership and portability path. Both use the same shortcut, history and output
formats.

### Developer-native output

A URL is only one representation. The same upload can produce a raw URL,
Markdown image, Markdown link or HTML, with predictable CLI and automation
behavior.

### Local-first handling

Clipboard inspection and file preparation happen on the Mac. User-owned
credentials stay in Keychain. Managed uploads should travel directly to object
storage rather than through the application API.

## Product boundaries

The first product is not:

- a screenshot editor;
- a floating drag-and-drop shelf;
- a team video-messaging suite;
- a general cloud drive or synchronization client;
- an anonymous, unlimited file host;
- only an S3 configuration interface.

Those are established categories. The opportunity is a small, universal
publishing command that composes with them.

## Why now

Coding agents and remote development have made the local/remote asset boundary
more visible. Developers also expect tools to support a native interface, CLI,
shortcuts and automation as one coherent system. S3-compatible storage and
direct-upload APIs make it practical to offer both hosted convenience and
user-owned infrastructure.

This is a product hypothesis, not proof of demand. The
[validation plan](validation-plan.md) defines the evidence required before a
full hosted service is built.

## Success signal

The strongest early signal is repeated weekly use of the shortcut in real work,
not downloads or setup completions. A viable initial cohort should publish
several times per week, understand where links are stored, and miss the command
when it is unavailable.
