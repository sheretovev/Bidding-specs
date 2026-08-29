# Changelog

All notable changes to this spec are recorded here, per version, naming the affected spec
IDs so a platform maintainer can scan for relevance without reading full diffs. See
`GOVERNANCE.md` §3 for what qualifies as MAJOR/MINOR/PATCH.

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
