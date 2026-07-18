# Security policy

Wirecopy handles clipboard contents, local files and storage credentials, so
security reports are taken seriously. The product has not launched; there are
no signed public releases yet and no bug bounty.

## Reporting a vulnerability

Report vulnerabilities privately. Do not open a public issue or pull request
for a security problem.

Contact: TODO(operator): publish a security contact email (and, once the
repository is public, enable GitHub private vulnerability reporting).

Include what you can: affected component, reproduction steps, impact and any
suggested fix. You should receive an acknowledgment before details are
discussed anywhere public, and reports stay private until a fix is available.

## Scope

In scope for this repository:

- the Swift client: the macOS menu-bar app, the `wirecopy` CLI and the shared
  `WirecopyCore` package (clipboard and file handling, Keychain token storage,
  archive creation, uploads);
- the build and install scripts under `macos/`;
- the published managed API contract, where the contract itself creates a
  vulnerability.

Vulnerabilities in the hosted managed service, its API implementation or its
infrastructure are covered by the private service repository's security
policy; report them through the same private contact and they will be routed
there.
