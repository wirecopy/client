# 0012: Write deterministic uncompressed ZIP archives in the client

- Status: Accepted and implemented
- Date: 2026-07-18 (recorded retroactively; the implementation already shipped
  with the native client in `WirecopyCore/DeterministicZip.swift`)

## Context

Two publishing paths package multiple files into one archive before upload:
selecting several files for an ordinary file link, and packaging a site folder
for the explicit `site` mode. If the archive bytes varied between runs, the
same logical publish would produce different objects each time. System `zip`
and general-purpose archive libraries embed modification timestamps, platform
metadata and library-version-dependent compression output, so their results
are not reproducible across machines or invocations.

The integration smoke harness downloads published objects and compares exact
bytes, and reproducible archives keep repeated publishes of identical content
identical at the storage layer. Shelling out to `zip` would also add an
external tool dependency the sandboxed app cannot rely on.

## Decision

`WirecopyCore` writes the ZIP container directly, byte for byte, with no
third-party or system archiver:

- Entries are stored uncompressed (method 0) with the UTF-8 name flag set.
- DOS timestamps are written as fixed constants: the mod-time field is zero
  and the mod-date field is `0x0021` (the DOS epoch, 1980-01-01). External
  attributes are fixed (regular file, mode 0644), so no machine or clock state
  leaks into the archive.
- Multi-file archives sort entries by filename using localized standard
  comparison; duplicate names get deterministic `-2`, `-3`, … suffixes and any
  `/` in a name becomes `_`.
- Site archives (`createSite`) sort entries by Unicode order of their
  folder-relative paths (Swift `String` comparison, locale-independent),
  skip hidden files and package descendants, reject
  symbolic links, reject any path containing a `..` segment, and require an
  `index.html` at the folder root.
- CRC-32 is computed in-process.

Given the same input files, the archive is identical on every run on the same
machine. Multi-file archives are not guaranteed identical across machines:
localized standard comparison collates by the current locale, so filenames
with diacritics or case differences can order differently under different
locales, changing the archive bytes. Site archives use locale-independent
Unicode ordering and are identical across machines.

## Consequences

- Repeated publishes of the same content produce identical objects, which
  keeps storage dedup-friendly and lets the integration harness verify exact
  bytes end to end.
- No compression: archives are as large as their inputs. This is accepted
  because typical payloads (images, PDFs, already-compressed assets) gain
  little from deflate, and uploads go directly to object storage.
- No ZIP64 support: entry sizes and offsets are 32-bit and the entry count is
  16-bit, so archives are limited to 4 GiB per entry and 65,535 entries. This
  is far above current publish limits.
- Symbolic links and traversal-shaped paths cannot enter a site archive, which
  removes one class of extraction and serving hazards before the archive
  reaches the managed service.
- The client owns a small amount of ZIP format code that must be kept correct,
  covered by `Tests/WirecopyCoreTests/DeterministicZipTests.swift`.

## Alternatives considered

Shelling out to `/usr/bin/zip` or linking libarchive would avoid hand-written
format code but produce nondeterministic bytes, add dependency surface and
still require post-hoc validation of symlinks and paths. Normalizing an
externally produced archive afterwards would be more code than writing the
simple uncompressed container directly.

## Revisit when

- publish limits approach the 4 GiB entry or 65,535 entry format bounds;
- large site folders make uncompressed upload size a real cost;
- a use case requires preserving timestamps, permissions or symlinks.
