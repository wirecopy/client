# 0003: Adopt Wirecopy as the product name

- Status: Accepted for implementation
- Date: 2026-07-16

## Context

The original working name, "Clipboard to Link," described the mechanism
rather than the act. It read as a generic "X to Y" converter utility, had no
usable verb or CLI form, and emphasized the clipboard when the thesis centers
on controlled publishing.

A replacement working name had to pass three screens:

- **CLI-first**: the name, or an obvious short form, must work as a terminal
  command alongside the Mac app, CLI and API.
- **Collision-free**: no active developer tool, Mac utility or adjacent
  product may already use the name.
- **Ownable domain**: a sane `.app` or `.dev` domain must be plausibly
  registrable at decision time.

Candidate research showed that evocative single dictionary words (uplink,
beam, chute, spool, hoist and similar) are uniformly domain-taken or collide
with established tools, so the realistic space is tasteful compounds or
revived vintage terms. The strongest conceptual vein was wire-transmission
and newsroom vocabulary, which matches both the product act (send over the
wire) and the publishing thesis.

## Decision

Adopt **Wirecopy** as the product name and public brand.

- "Copy" carries three aligned meanings: the clipboard copy gesture,
  journalism copy filed for publication, and *wire copy*, the newsroom term
  for content that arrived over the wire.
- "Over the wire" is living developer vocabulary and suits an
  infrastructure-grade trust story (private files, revocation, user-owned
  credentials).
- The CLI command is `wirecopy`, with `wire` reserved as a possible short
  alias.
- Verified on 2026-07-15/16: `wirecopy.app` and `wirecopy.dev` were
  unregistered (RDAP), and no active product uses the name. Known
  non-blocking collisions: a ProcessWire API function `wireCopy()` and an
  AutoCAD wire-copy command.
- `wirecopy.app` is the sole domain: primary site, downloads and share links.
  For a Mac-native product the `.app` TLD matches the platform idiom, and its
  enforced HTTPS suits a product whose output is links others click.
  `wirecopy.dev` is deliberately not registered; the squat risk is accepted
  rather than paying for a defensive registration.

Use `wirecopy.app` as the canonical domain. Do not register `wirecopy.dev` only
for defensive ownership. Domain registration, a trademark screen and signed
release artifacts remain launch gates; selecting the brand does not claim that
the product has launched.

## Consequences

### Positive

- The name narrates the workflow (copy, then wire) instead of describing
  plumbing, and works verbally ("wirecopy it to me").
- One name serves the app, CLI, API and documentation without a separate
  command name.
- The app, CLI, API, documentation and managed service can share one name.

### Negative

- The name is literal rather than warm; it trades brand personality for
  infrastructure credibility.
- If `wirecopy.app` is not registered promptly, the availability evidence
  expires and the decision may need to be revisited.
- Skipping `wirecopy.dev` means a squatter could later hold the closest
  developer-facing domain; docs and API surfaces must live under
  `wirecopy.app` subdomains.
- Repository, folder, bundle identifiers, executable names and service names
  must move from `clipboard-to-link` to Wirecopy before application scaffolding.

## Alternatives considered

### Pastepot

The newsroom paste pot: clean collisions, `pastepot.app` free, the warmest
brand personality of the shortlist. Rejected because "paste" plus a container
noun pattern-matches to pastebin-style text hosts, and the cutesy register
undercuts the security and control story.

### Telecopy

"Copy at a distance," the etymology of the French word for fax.
`telecopy.app` was free, but the fax connotation reads slow and dying —
directly against the "materially faster" positioning — and "Tele-" invites
Telegram confusion.

### Wirephoto

The AP's 1935 photo-over-wire service; the trademark lapsed in 2004 and
`wirephoto.app` was free. Rejected because the product publishes arbitrary
files, not only images.

### Pasteup, Pastewire and other compounds

Pre-press and wire-service compounds (`pasteup.app`, `pastewire.app` free)
from the same vein. Viable fallbacks, but weaker than Wirecopy at naming the
act rather than the material.

### Keeping a descriptive placeholder

Deferring naming entirely was rejected because the placeholder was already
leaking into documents, decision records and the repository name, raising the
eventual cost of change.

## Revisit when

- the domains cannot be registered at reasonable cost, or a trademark screen
  fails;
- the product scope shifts away from developer infrastructure toward a
  consumer or playful positioning, where Pastepot-style warmth fits better;
- a real collision surfaces that the 2026-07 research missed.
