# 2. Spec versioning and how platform repos reference this repo

## Status

Accepted

## Context

`bidding-web` and `bidding-app` were built independently against the same backend and
already disagree on details that matter (see `platform-notes/*.md`): `bidding-web` doesn't
implement the own-action floor for real-time reconciliation that `bidding-app` does;
`bidding-app` has no equivalent of `bidding-web`'s post-auction Sales Order flow at all.
Neither repo had anywhere to record "this is the intended shared behavior" independent of
"this is what one app currently happens to do." Without a versioning and reference
convention, this repo risks becoming exactly the kind of document everyone means to check but
nobody actually keeps in sync with — the same failure mode that produced the drift in the
first place.

## Decision

1. This repo is tagged `vMAJOR.MINOR.PATCH` on every meaningful change (see `GOVERNANCE.md`
   §3 for what qualifies as each).
2. Every normative rule carries a stable ID (`SPEC-<AREA>-<NNN>`), never renumbered once
   published — a rule that's removed is marked deprecated in place (with a pointer to why,
   likely another ADR) rather than having its ID reused for something else later.
3. Each platform repo records the exact tag it targets, and cites spec IDs when implementing
   or reviewing bidding logic (full rationale in `GOVERNANCE.md` §2).
4. `contracts/domain-contract.yaml` is the one artifact explicitly designed to be machine-
   diffed; everything else in `domain/` is human reference only, deliberately not forced into
   a schema.
5. A monorepo merge of `bidding-web`/`bidding-app`/`bidding-specs` is explicitly rejected in
   favor of a lightweight manifest layer, if/when a "clone everything" workflow is needed
   (`GOVERNANCE.md` §4) — the repos' build systems have no reason to merge.

## Consequences

- A platform bumping its pinned spec tag is a visible, reviewable event, not a silent
  behavior change.
- `platform-notes/*.md` becomes the honest, current record of drift — this decision doesn't
  eliminate drift (that's not realistic across two independent codebases and tech stacks),
  it makes drift *visible and intentional* instead of accidental.
- Overhead: maintaining `contracts/domain-contract.yaml` in sync with `domain/*.md` prose is
  a manual discipline for now (no generator exists yet). If this repo grows enough that
  manual sync becomes error-prone, generating the YAML from annotated Markdown (or vice
  versa) is a reasonable future revisit — not needed at this repo's current size.
