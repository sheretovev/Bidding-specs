# Bidding Specs

This repository is the **single source of truth for how a bidding platform must behave**,
independent of whether it is rendered as a website, an iOS app, an Android app, or anything
else built later. It exists because [`bidding-web`](https://github.com/sheretovev/Bidding-web)
and [`bidding-app`](https://github.com/sheretovev/Bidding-app) (iOS) are two independent
front ends for the same auction backend ("PurpleUnity"), and they were starting to drift:
the same rule (e.g. what increment applies during an anti-snipe extension) was implemented
twice, in two languages, with no shared reference either implementation could be checked
against.

**The rule going forward: business/domain rules are written here first. A platform
implements them; it does not invent them.** If a new platform (Android, a kiosk app, a
partner integration) needs to know how bidding works, it starts by reading this repo — not
by reverse-engineering `bidding-web` or `bidding-app`.

## What this repo is not

- It is not a UI spec. Layout, navigation, visual design, and platform-idiomatic UX are each
  platform's own decision. This repo defines *what must be true*, not *how it must look*.
- It is not a replacement for the backend's own API contract. Where the backend (PurpleUnity)
  publishes an authoritative schema (OpenAPI/Swagger, SignalR hub contract), that schema wins
  on exact field names and types. This repo curates and explains the subset of that surface
  that encodes *bidding business rules* — the parts a client can get subtly wrong even while
  technically matching the schema (e.g. "which increment applies right now").

## Repo map

```
domain/           The rules themselves — one topic per file, platform-agnostic.
contracts/        The concrete, checkable shape of those rules: enums, event payloads,
                   the REST/WebSocket surface a bidding client depends on.
conformance/       A checklist and Gherkin-style scenarios a platform implementation
                   should be able to point its own tests at.
platform-notes/    Per-platform notes: how bidding-web and bidding-app currently map to
                   this spec, and where they knowingly deviate or fall short.
decisions/         ADRs — why the spec says what it says, and how the spec itself is governed.
```

Start with [`domain/00-glossary.md`](domain/00-glossary.md) for shared vocabulary, then
[`domain/01-auction-lifecycle.md`](domain/01-auction-lifecycle.md) and
[`domain/02-lot-lifecycle.md`](domain/02-lot-lifecycle.md) for the two state machines
everything else builds on.

## How a platform repo should reference this spec

See [`GOVERNANCE.md`](GOVERNANCE.md) for the full model. In short:

1. Pin a version. Each platform repo's `CLAUDE.md`/`CONTRIBUTING.md` names the tag of this
   repo it was built against (e.g. `bidding-specs@v1.2.0`), not "latest" — a spec change
   should be a deliberate, reviewed bump in the platform repo, not something that silently
   changes behavior underneath it.
2. Cite spec IDs, not just this repo's existence. Every domain file's rules are numbered
   (`SPEC-BID-003`, `SPEC-EXT-001`, ...). A platform's code comment, PR description, or test
   name that implements a rule should cite its ID, so "does this app actually implement
   `SPEC-EXT-001`" is a grep, not an investigation.
3. Treat [`contracts/domain-contract.yaml`](contracts/domain-contract.yaml) as the one file
   worth actually diffing against in CI — it's the machine-readable subset of the domain
   rules (state names, increment logic flags, event names) most likely to silently drift.
4. Run the [`conformance/checklist.md`](conformance/checklist.md) against your platform
   before shipping bidding-related changes, and keep [`platform-notes/`](platform-notes/) for
   your platform current — it's the honest record of "spec says X, we currently do Y, because
   Z" rather than a silent gap someone else has to rediscover.

## Current spec version

See [`CHANGELOG.md`](CHANGELOG.md) and [`VERSION`](VERSION).
