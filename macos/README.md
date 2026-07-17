# Wirecopy for macOS

Native macOS 14+ menu-bar app and standalone CLI, implemented in Swift 6 and
SwiftUI. Both use `WirecopyCore` for clipboard/file preparation, deterministic
multi-file ZIPs, managed upload intents, direct object uploads, lifecycle
polling, formatting and local history.

The native menu and Settings surfaces share the dashboard's Wirecopy design
system: the web OKLCH palette is converted to exact sRGB values for macOS,
Newsreader is used for display type, and Geist is used for interface copy.
Both fonts and their SIL Open Font License files are bundled with the app, so
development previews and installed builds do not depend on fonts installed on
the machine. Light appearance matches the web palette directly; dark appearance
uses an accessible tonal adaptation of the same hues.

## Development setup

Start the Rails service first:

```sh
cd ~/personals/wirecopy/service
mise x -- bin/setup --skip-server
mise x -- bin/dev
```

Create a token at <http://localhost:3000/device_tokens>. Then build and run the
menu-bar app:

```sh
cd ~/personals/wirecopy/client/macos
swift build
swift run WirecopyApp
```

Click the paper-plane menu-bar icon, open Settings, keep the server as
`http://localhost:3000`, paste the `wc_live_…` token and Save. You can now:

- copy a Finder file or image and press **Control–Option–C**;
- choose one or several files from the menu;
- drag files onto the open menu-bar panel;
- copy, open or revoke the latest link;
- use recent local history without opening the Rails dashboard.

Publishing does not open the menu automatically. Its icon changes from a
processing state to a rotating ring that reflects real upload progress, then
smoothly becomes a completion checkmark for two seconds after the link is
copied. Failures remain visible until dismissed or replaced by a successful
publish. Recent-link actions remain in their row; copying there briefly changes
that row's copy icon to a green checkmark. Deletion requires a second press on
the inline `Delete?` confirmation.

Plain text is deliberately ignored. Multiple files are packaged into a
byte-for-byte deterministic, uncompressed ZIP. Folders remain outside the
ordinary file-link workflow. The explicit CLI `site` command can package a
folder with a root `index.html` and publish it to an isolated managed origin.

## Visual verification harness

Render either native SwiftUI surface in a regular window without reading a
real Keychain token or contacting the service:

```sh
WIRECOPY_UI_PREVIEW=menu WIRECOPY_TOKEN=wc_preview_token swift run WirecopyApp
WIRECOPY_UI_PREVIEW=settings WIRECOPY_TOKEN=wc_preview_token swift run WirecopyApp
WIRECOPY_UI_PREVIEW=menu WIRECOPY_UI_APPEARANCE=light WIRECOPY_TOKEN=wc_preview_token swift run WirecopyApp
WIRECOPY_UI_PREVIEW=settings WIRECOPY_UI_APPEARANCE=dark WIRECOPY_TOKEN=wc_preview_token swift run WirecopyApp
```

The harness is environment-gated and does not add a production window. It is
intended for screenshots, accessibility inspection and noninteractive visual
checks of typography, spacing, adaptive colors and control states. The menu
preview uses deterministic sample history, including a long filename and
minute-granularity timestamps, without touching the user's real history.

## CLI

During development, use the wrapper:

```sh
./bin/wirecopy configure --server http://localhost:3000 --token 'wc_live_…'
./bin/wirecopy publish ~/Desktop/report.pdf
./bin/wirecopy publish one.png two.pdf --format markdown
./bin/wirecopy publish --clipboard --json
./bin/wirecopy site ./dist
./bin/wirecopy site ./prototype.zip --json
./bin/wirecopy links
./bin/wirecopy links revoke 123
```

`WIRECOPY_SERVER`, `WIRECOPY_TOKEN` and `WIRECOPY_EXPIRES_IN` override stored
configuration, which makes CI and self-built clients noninteractive. Progress
goes to stderr; the link or JSON result goes to stdout.

`wirecopy site` accepts one `.html`, `.htm`, `.zip`, or folder. Folder paths are
preserved in a deterministic ZIP and the managed API receives an explicit
`mode=site`; ordinary `wirecopy publish index.html` remains a file link.

## Tests and real-service verification

```sh
swift test
./scripts/integration-smoke
```

The integration harness starts Rails on an isolated port, provisions a
temporary device token, publishes through the native CLI, uploads directly to
MinIO, downloads and compares the exact bytes, revokes the link, verifies HTTP
410 and cleans up without input.

## Build and install a development app

```sh
./scripts/install-dev
open ~/Applications/Wirecopy.app
```

This creates a release build, bundles the CLI at
`Wirecopy.app/Contents/MacOS/wirecopy`, generates an `.icns`, applies an ad-hoc
local signature and installs it under `~/Applications`. It is not notarized and
is not a distributable release.

Artifacts are written under `dist/`. Generate a local Cask definition with:

```sh
./scripts/build-local-cask
```

Official Homebrew distribution still requires a stable release URL, Developer
ID signing, notarization and published checksums. The template is in
`Casks/wirecopy.rb.template`.
