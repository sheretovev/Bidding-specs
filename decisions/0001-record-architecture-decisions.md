# 1. Record architecture decisions

## Status

Accepted

## Context

This spec will change over time — a rule will get clarified, a genuinely contested design
choice will need to be made (e.g. how Buy Now should interact with Extended, `SPEC-RES-003`),
or a platform-specific deviation will need a documented rationale rather than a silent
divergence. If those decisions only ever live as edits to `domain/*.md`, the *why* behind a
rule is lost the next time it's revised, and two people can re-litigate the same settled
question because neither can find where — or whether — it was already decided.

## Decision

We use lightweight Architecture Decision Records (ADRs) under `decisions/`, numbered
sequentially, using this file as the template: Status / Context / Decision / Consequences.
An ADR is written for:

- Any change to a `domain/*.md` rule that isn't purely editorial (see
  `GOVERNANCE.md` §3 on MAJOR/MINOR/PATCH).
- Any open question a domain file explicitly flags for later resolution (e.g. `SPEC-RES-003`'s
  Buy Now/Extended interaction).
- Any platform's deliberate, permanent deviation from a spec rule (as opposed to a temporary
  gap tracked in `platform-notes/`) — if a platform decides a rule genuinely shouldn't apply
  to it, that's a decision worth recording here, not a silent exception.

An ADR is never deleted or renumbered once merged, even if a later ADR supersedes it — mark
it "Superseded by ADR-000X" in its Status line instead, so the history of *why* stays intact.

## Consequences

- Anyone asking "why does the spec say X" has one place to check before assuming it's
  arbitrary or asking someone who may not remember either.
- Contested changes get a forcing function (write the tradeoff down) instead of being decided
  in a PR comment thread that isn't discoverable later.
- Slight overhead: a genuinely trivial clarification doesn't need this ceremony — use
  judgment, and see `GOVERNANCE.md`'s PATCH-level changes for the "no ADR needed" case.
