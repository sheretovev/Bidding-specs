# Changelog

All notable changes to this spec are recorded here, per version, naming the affected spec
IDs so a platform maintainer can scan for relevance without reading full diffs. See
`GOVERNANCE.md` §3 for what qualifies as MAJOR/MINOR/PATCH.

## [Unreleased]

### Added

- `domain/11-home-category-browsing.md` (`SPEC-CAT-001`..`006`) — home screen category tiles
  sourced from taxonomy, acting as a live filter on a canonical "Ending Soon" lots query
  (running/extended only, soonest-closing first). Neither platform fully implemented this
  before now; ports to both as part of the same change that added this spec section.
- `contracts/taxonomy-icon-map.md` — the shared, explicitly-provisional icon-name vocabulary
  and per-platform glyph mapping, with a mandatory default-fallback rule.
- `decisions/0003-home-category-browsing.md` — records the subtree-matching approximation
  (category + fetched direct children only, pending backend schema confirmation for deeper
  matching) and the section-ordering call (category browsing above personalized bid status).
- Glossary: added Taxonomy/Category and Icon Name terms, removed the earlier "taxonomy is
  out of scope" line now that it's a first-class spec area.

### Added

- `conformance/audit-2026-08-31.md` — a full, verified rule-by-rule conformance audit of
  both `bidding-web` and `bidding-app` against every rule in `domain/*.md`, done by tracing
  actual code paths (not the partial sampling `v0.1.0`'s platform notes were based on).
  Headline: neither platform fully conforms, and the gaps are largely non-overlapping —
  iOS is stronger on lifecycle gating, anti-sniping, and real-time reconciliation; web is
  stronger on fulfillment, max-bid leading status, and bidder-identity masking. See the
  audit's prioritized punch list for recommended fix order.

### Changed

- `platform-notes/web.md` and `platform-notes/ios.md` rewritten against the new audit —
  several rules the initial version marked "conforms" (notably web's SPEC-LOT-002/
  SPEC-BID-001, entirely unimplemented rather than imperfect) were corrected.

## [0.1.0] - 2026-08-29

Initial version. Establishes the spec repo and distills the bidding domain rules observed
across `bidding-web` and `bidding-app` (both consuming the shared PurpleUnity auction
backend) into a platform-agnostic reference.

### Added

- `domain/00-glossary.md` through `10-currency-and-multi-tenancy.md` — the full initial rule
  set: auction lifecycle (`SPEC-AUC-*`), lot running-state lifecycle (`SPEC-LOT-*`), bid
  placement and validation (`SPEC-BID-*`), max bid / proxy bidding (`SPEC-MAX-*`),
  anti-sniping extension (`SPEC-EXT-*`), real-time update reconciliation (`SPEC-RT-*`),
  reserve price and buy-now (`SPEC-RES-*`), post-auction fulfillment (`SPEC-FUL-*`),
  identity and access (`SPEC-AUTH-*`), and currency/multi-tenancy (`SPEC-I18N-*`).
- `contracts/domain-contract.yaml`, `contracts/websocket-events.md`,
  `contracts/rest-api-surface.md` — the machine-checkable and reference-API layer.
- `conformance/checklist.md` and `conformance/scenarios.feature`.
- `platform-notes/web.md` and `platform-notes/ios.md` — initial conformance snapshot for
  both existing platforms, including known gaps (`bidding-web` lacks the SPEC-RT-004
  own-action floor and has a slightly early "connected" signal; `bidding-app` has no
  fulfillment/Sales Order flow at all).
- `decisions/0001-record-architecture-decisions.md`,
  `decisions/0002-spec-versioning-and-reference-model.md`.
- `GOVERNANCE.md` — the reference/versioning/multi-repo model.

### Known open items (see linked ADR/spec sections)

- Buy Now's exact interaction with the Extended state is unresolved (`SPEC-RES-003`).
- `bidding-app` fulfillment gap (`platform-notes/ios.md`).
- `bidding-web` real-time reconciliation gaps (`platform-notes/web.md`).
