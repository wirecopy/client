# Business model

## Business thesis

This can become a durable, bootstrapped Mac utility and managed-service
business if the shortcut develops into a repeated habit. The current evidence
does not support assuming venture-scale demand.

Revenue should align with the two storage modes:

- **Bring your own storage:** free core or a one-time application license.
- **Managed cloud:** recurring subscription for storage, lifecycle, links and
  operations.

The exact packaging remains a hypothesis until workflow and willingness-to-pay
tests are complete.

## Why a hybrid model fits

BYOS users create little recurring storage cost and often value ownership.
Managed users purchase convenience and create ongoing infrastructure, support
and abuse costs. Charging both groups only by upload count would poorly match
cost and perceived value.

BYOS can also distribute the app among technical users without subsidizing
their file storage. The managed path can monetize users who prefer not to
configure infrastructure.

## Packaging hypotheses

| Offering | Candidate value | Candidate price |
| --- | --- | ---: |
| Free local/BYOS | Core shortcut, one S3 destination, raw/Markdown output, limited history | $0 |
| Mac Pro license | Multiple presets/destinations, advanced output, CLI/integrations, full local history | One-time price to test |
| Managed Free | Immediate hosted setup, short retention and modest daily/byte limits | $0 |
| Managed Pro | More storage, larger files, configurable retention, custom domains and richer controls | $5–8/month hypothesis |
| Team | Shared domains, policies, billing and administration | Later, only after individual pull |

Avoid manufacturing incompatibility between local and managed modes. Paid value
should come from meaningful capability and operating cost, not friction in the
core shortcut.

## Unit-economics model

Track contribution by cohort using:

```text
subscription revenue
− payment and tax costs
− stored GB-months
− storage operation costs
− compute, metadata and delivery costs
− scanning and preview costs
− support, abuse and fraud allocation
= contribution margin
```

Direct object-storage egress pricing can be favorable while downstream compute,
edge requests and abusive traffic still cost money. Model the entire delivery
path.

## Limits and fair use

Plans need multiple controls because usage shapes differ:

- uploads per day or month for comprehensibility;
- maximum file size to bound failure and abuse;
- active stored bytes to reflect cost;
- default and maximum retention;
- download abuse thresholds;
- packaging and processing limits.

Do not market “unlimited” unless the financial and abuse model genuinely
supports the worst credible use.

## Metrics

### Activation

- shortcut configured successfully;
- first supported asset published;
- first link pasted or copied;
- setup time and failure reason by storage mode.

### Habit and retention

- publishing users per week;
- uploads per active publishing user;
- weeks with at least one publish action;
- time from copy to link;
- destination and output format reuse;
- shortcut failure or cancellation rate.

### Managed economics

- uploaded and active bytes per account;
- retention distribution;
- download bytes and request distribution;
- cost per active/free/paid account;
- free-to-paid conversion;
- gross and contribution margin;
- abuse/support incidents per thousand links.

Metrics require an explicit privacy inventory. Local/BYOS behavior should not be
uploaded merely because it would make product analytics easier.

## Go-to-market hypothesis

The initial demonstration is ten seconds long: copy a screenshot or Finder file,
press the shortcut, and paste a Markdown or raw link into a terminal or GitHub.

Likely channels:

- a public build-in-public narrative around the remote-development workflow;
- Homebrew and direct signed distribution;
- developer communities using coding agents, terminals and remote boxes;
- integrations for Raycast, Alfred, Shortcuts and Herdr;
- clear comparison pages that acknowledge direct alternatives honestly;
- an open or inspectable CLI contract, depending on licensing strategy.

Search positioning should target the job (“clipboard file to link,” “Mac upload
hotkey,” “S3 clipboard uploader”) while the brand remains broad enough for the
managed service.

## Stop conditions

Do not build a full hosted platform merely because storage appears inexpensive.
Pause or narrow the product if:

- users like the demo but do not repeat the shortcut weekly;
- most users prefer an existing shelf or screenshot editor;
- BYOS setup/support dominates the value of the workflow;
- managed-cloud willingness to pay cannot cover realistic operating costs;
- abuse controls make a useful free tier untenable;
- platform permissions make the default command unreliable.
