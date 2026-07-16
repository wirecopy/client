# 0008: Require a non-interactive verification harness

- Status: Accepted for implementation
- Date: 2026-07-16

## Context

Wirecopy spans a native client, CLI, private Rails service, object storage,
authentication, billing, malware scanning and public-link lifecycle. Manual
testing cannot reproducibly cover that system or provide enough evidence for a
safe release. Contributors and automated agents also need to validate work
without asking the product owner to configure accounts or click through flows.

## Decision

Both repositories provide a non-interactive `./scripts/verify` entry point.

- Default mode runs lint, unit, contract and disposable PostgreSQL/MinIO
  integration tests without external credentials.
- Full mode adds real ClamAV and complete managed-lifecycle scenarios.
- Release mode uses CI-provided isolated provider credentials for R2/S3
  conformance, recovery and signed Cask tests.
- Local Clerk, Dodo, time, scanner, network and storage fault simulators produce
  deterministic success and failure states.
- Every run emits JUnit, JSON manifest, coverage, compatibility and redacted
  diagnostic artifacts.
- Production credentials and targets are rejected by guardrails.
- Required skipped or flaky scenarios block a release.

The full design and scenario matrix live in
[Automated testing harness](../testing-harness.md).

## Consequences

### Positive

- Developers and agents can verify changes without human setup.
- Direct upload, quarantine, billing and deletion behavior remain testable as
  one system.
- Machine-readable evidence supports release review and regression diagnosis.
- Simulated time and failure injection test cases that are impractical manually.

### Negative

- Simulators and fixture contracts require maintenance alongside providers.
- macOS packaging and real-provider jobs add CI cost and secret management.
- A full verification run is slower than unit tests.
- Passing MinIO and simulated providers does not replace scheduled real-provider
  conformance.

## Revisit when

- provider sandboxes offer a safer or more faithful replacement for a simulator;
- CI cost requires splitting scheduled suites without weakening release gates;
- a new runtime dependency expands the environment matrix;
- observed flaky infrastructure requires improved isolation.
