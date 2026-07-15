# Validation plan

The riskiest question is not whether a Mac can upload a copied file. It is
whether a sufficiently specific audience will repeatedly choose this publishing
command over native paste, scripts and established applications.

## Stage 1: problem evidence

Interview 12–20 developers who regularly use at least two of: remote
development, coding agents, terminals, GitHub, Markdown or technical chat.

Ask for recent behavior, not feature opinions:

- Show the last time you shared a local screenshot with a remote environment.
- What did you copy, where did it need to go and what steps did you take?
- Which uploader, drive, script or native behavior did you use?
- What failed or felt unsafe?
- How often did this happen in the last seven days?
- Which links needed expiration, revocation or permanence?
- Do you already pay for a tool that covers it?

Record current alternatives and observed frequency. Do not pitch the solution
until the workflow is understood.

### Gate

Proceed when at least eight participants demonstrate a recurring workflow and a
meaningful subset uses an awkward workaround despite knowing common
alternatives.

## Stage 2: positioning and prototype

Test a landing page and a clickable/native prototype using several messages
from [Differentiation](differentiation.md). The prototype needs only:

- clipboard image and Finder-file input;
- shortcut selection and conflict feedback;
- visible upload progress and failure notification;
- raw URL and Markdown output;
- a fake or temporary managed destination;
- recent result with revoke/delete behavior represented accurately.

Measure whether users can explain the product, predict what the shortcut will
do and choose the intended output without instruction.

### Gate

Proceed when the core message is understood without a long explanation and
participants prefer the shortcut for at least one existing workflow.

## Stage 3: local/BYOS concierge beta

Build the smallest reliable native path and onboard 20–30 users manually. Start
with a deliberately narrow compatibility matrix. Observe setup rather than only
collecting bug reports.

Track locally or with explicit consent:

- setup completion and time;
- publish success/failure by input type;
- weekly repeated use;
- output format selection;
- shortcut conflicts;
- storage configuration support load;
- user attempts outside the supported matrix.

### Gate

After four weeks, a meaningful core cohort should still publish multiple times
per week. Target thresholds are hypotheses: at least 40% weekly retention among
activated testers and a median of three or more weekly publishes in the retained
cohort.

## Stage 4: managed-cloud willingness to pay

Before building full billing and operations, offer a clearly bounded hosted
beta. Test:

- immediate managed setup versus BYOS;
- 24-hour and configurable retention;
- maximum-file and active-storage limits;
- candidate $5–8 monthly pricing;
- transparent usage display;
- account, revoke, delete and abuse flows.

Use real payment intent where practical. A survey answer that a price “sounds
reasonable” is weak evidence.

### Gate

Proceed to production operations only when paid conversion and observed storage
behavior support a conservative contribution-margin model with abuse and
support allowance.

## Stage 5: compatibility expansion

Add input types by observed demand and automated fixtures:

1. clipboard PNG/JPEG and single Finder file;
2. multiple files and folders/ZIP;
3. PDFs, video, audio, archives and large uploads;
4. iCloud placeholders, file promises, packages, aliases and symlinks;
5. Share extension, Finder action, Shortcuts and third-party integrations.

Maintain a tested matrix across supported macOS versions and Apple hardware.
Public copy must match it.

## Competitor trials

Conduct hands-on trials of Dropshare, Dropover and relevant screenshot tools.
For the same tasks, record:

- install and time-to-first-link;
- shortcut configuration and conflicts;
- clipboard/Finder behavior;
- hosted and S3 setup;
- output-format choices;
- expiration/revocation behavior;
- failure feedback;
- history and deletion;
- CLI/automation surface;
- price and licensing at the observation date.

The goal is to understand switching value, not manufacture a comparison table
where this product wins every row.

## Evidence log template

For each experiment, add a dated note containing:

```markdown
# Experiment: <name>

- Date:
- Owner:
- Hypothesis:
- Participants/sample:
- Method:
- Success criterion set before the test:
- Observations:
- Result:
- Decision:
- Follow-up:
```

Store anonymized conclusions in the repository. Do not commit interview
recordings, personal data, credentials or private customer files.
