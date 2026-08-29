# Governance: how this spec is controlled, and how platforms reference it

This document answers the operational question behind the whole repo: *specs are nice, but
how do I actually keep two-plus independent codebases honest against them, long term?*

## 1. What kind of reference is this — dev reference, or something enforceable?

Both, deliberately split into two tiers:

- **Tier 1 — human reference (`domain/*.md`, `decisions/*.md`).** Prose, rationale, edge
  cases, "why it's like this." This is what an engineer reads once when building a feature,
  or when a bug report smells like a spec violation. It is not machine-checked, and it
  shouldn't try to be — rationale doesn't compress into a lint rule.
- **Tier 2 — practical/checkable reference (`contracts/*`).** The small, literal subset of
  the domain that *can* be pinned down as data: state-name strings, which running states
  accept bids, which fields a `HighestBidUpdate`-equivalent push must carry, endpoint paths.
  `contracts/domain-contract.yaml` is written so a platform repo *can* (not must, initially)
  add a CI step that parses it and asserts its own hardcoded state strings/enums match — the
  kind of drift that caused this repo to exist (a rename like `"Live"` vs `"Running"` used
  inconsistently between `bidding-web` and `bidding-app` today, see `platform-notes/`).

Don't try to make Tier 1 executable — you'll end up either under-specifying the rule to fit
a schema, or writing a DSL nobody reads. Don't leave Tier 2 as prose only — "the increment
during Extended is `extendedIncrementPrice`" is exactly the kind of one-line fact that a
diff-able YAML file catches a regression on, and a paragraph doesn't.

## 2. How a platform repo references the spec (without copy-pasting it)

**Pin, don't float.** Each platform repo records the exact tag of `bidding-specs` it targets
(a line in `CLAUDE.md`/`CONTRIBUTING.md`/a `SPEC_VERSION` file — pick one convention and use
it in every platform repo the same way). Bumping that pin is its own reviewed PR, exactly
like bumping any other dependency. This is the difference between "the spec is a wiki page
people forget to check" and "the spec is a dependency with a version number."

**Cite spec IDs in code, not just "see bidding-specs."** Every normative rule in `domain/`
carries a stable ID (`SPEC-BID-003`, `SPEC-EXT-001`, `SPEC-MAX-002`, ...). When a platform
implements one, the commit message, PR description, or a one-line code comment should name
the ID. This buys you:
- `grep -r "SPEC-EXT-001" bidding-app/ bidding-web/` tells you, today, whether both platforms
  actually implement anti-sniping the same way, without reading either codebase end to end.
- A spec change to `SPEC-EXT-001` can be paired with "search both platform repos for this ID
  and check whether the change affects them" as a mechanical step, not a guess.

**Don't build a shared code library across web and iOS just to enforce this.** The two
platforms are React/JS and Swift; a shared runtime library would mean either a rewrite of one
platform's stack or a thin, low-value wrapper nobody trusts. Cross-platform enforcement lives
at the *data and process* layer instead: the YAML contract, the conformance checklist, and
spec-ID citations — not a shared `bidding-core` package. If a third platform in a *compatible*
stack shows up later (say, a second React web client), *that* is a reasonable point to extract
shared logic — but as a decision made then, against a concrete need, not speculatively now.

**Traceability is pull, not push.** This repo does not scan platform repos. A platform repo
(or a CI job inside it) pulls this repo's `contracts/domain-contract.yaml` at its pinned tag
and checks itself against it. Keeping the direction pull-only means adding a fourth platform
never requires touching this repo's tooling.

## 3. Versioning and change process

- Semantic-ish tags: `vMAJOR.MINOR.PATCH`.
  - **MAJOR**: a rule changes in a way that breaks an existing, correct implementation (e.g.
    the minimum-increment formula changes, a running state is renamed or removed).
  - **MINOR**: a new rule is added that platforms *should* eventually implement but that
    doesn't invalidate existing behavior (e.g. a new lot state for a feature no platform has
    yet built).
  - **PATCH**: clarification, typo fix, added rationale — no normative change.
- Every change to `domain/` or `contracts/` gets a `CHANGELOG.md` entry naming the affected
  spec IDs, so a platform maintainer can scan the changelog for "did anything I implement
  change" without reading every diff.
- Non-trivial or contested rules get an ADR under `decisions/` (see
  `decisions/0001-record-architecture-decisions.md`) instead of being silently edited in
  place — the "why" survives even after the rule itself is later revised.
- A rule this spec states that **no platform currently implements** (e.g. Buy Now as an
  actual purchase action — see `domain/07-reserve-price-and-buy-now.md`) is still recorded
  here as the target, with the gap tracked in both platforms' `platform-notes/` entries. The
  spec describes the intended system, not the least common denominator of what exists today.

## 4. Multi-repo workspace: is a monorepo the answer?

No — not a merge of build systems, but a **thin manifest layer on top of the existing
polyrepo**, for exactly the cases where "look at the whole platform at once" is genuinely
useful (onboarding, a full-stack local run, an architecture review):

- Keep `bidding-specs`, `bidding-web`, `bidding-app`, and any future `bidding-android`/etc.
  as separate repos with independent CI/CD, release cadence, and language tooling. Merging
  a React app and an Xcode project into one repo buys nothing — their build graphs never
  intersect.
- If you want a single "clone everything and see it all" entry point, add a small **manifest
  repo** (or repurpose this repo's root for it) that does nothing but pin commits/tags of
  each platform repo — either via git submodules, or a plain `manifest.yaml` a script reads
  to clone each repo at a pinned ref. This is the same shape as Android's `repo` tool or a
  `.gitmodules`-based workspace: one shallow, low-maintenance layer, not a merge.
- The manifest's only job is "these versions are known to work together" — e.g. `bidding-web
  v3.1` + `bidding-app v1.4` were both validated against `bidding-specs v1.2.0`. That mapping
  is itself useful history worth keeping, independent of any monorepo question.
- Revisit this if the number of platforms grows enough that manually keeping the manifest
  current becomes the bottleneck — that's a "add automation to the manifest," not a "merge
  the repos," problem.
