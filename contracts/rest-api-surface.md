# REST API Surface (bidding-critical subset)

This is **not** a full API reference — the backend's own OpenAPI/Swagger is authoritative for
exact schemas, required/optional fields, and error shapes. This lists only the endpoints that
encode the domain rules in `domain/*.md`, so a new platform knows what it needs to call and
why, and so a change to one of these specifically is a signal to re-check the linked spec
rules.

All calls below require the Public Environment scoping (`SPEC-I18N-001`) via an `apiKey`
header/query param and the environment path; ones marked **auth** additionally require a
bearer token (`SPEC-AUTH-001`).

## Auctions

| Call | Purpose | Spec refs |
|---|---|---|
| `GET /query/.../auctions` | List/browse. | SPEC-AUC-001 |
| `GET /query/.../auctions/{id}` | Auction details (dates, type, organising company). | SPEC-AUC-001, SPEC-AUC-002, SPEC-AUC-004 |
| `POST /query/.../auctions/{id}/live-data` / `POST /query/.../auctions/live-data` (batch) | Auction-level Running State rollup. | SPEC-AUC-003 |

## Lots

| Call | Purpose | Spec refs |
|---|---|---|
| `GET /query/.../lots/{id}` | Lot details: pricing, increments, buy-now, reserve config. | SPEC-LOT-*, SPEC-BID-002, SPEC-RES-* |
| `POST /query/.../lots/live-data` (batch by id) | Current Running State, highest bid, `isReservedPriceMet`, `extendedEndDate`. Poll this to gate bid controls (`SPEC-LOT-002`) and as the REST half of reconciliation (`SPEC-RT-003`). | SPEC-LOT-*, SPEC-EXT-*, SPEC-RT-* |

## Bids

| Call | Purpose | Spec refs |
|---|---|---|
| `POST /auction-engine/.../bids` **(auth)** — `{ lotId, amount }` | Place a plain Bid. | SPEC-BID-001..004 |
| `POST /auction-engine/.../max-bids` **(auth)** — `{ lotId, amount }` | Place/raise a Max Bid ceiling. May trigger an immediate server-side auto-bid. | SPEC-MAX-001, SPEC-MAX-004 |
| `GET /query/.../bids/history?auctionId=&lotId=&page=&pageSize=` | Public bidding history for a Lot (Open auctions only, per client-side branching). | SPEC-BID-005, SPEC-AUC-002 |
| `GET /query/.../bids/own` **(auth)** | The signed-in bidder's own plain Bids, with `isLeading`. | SPEC-BID-006 |
| `GET /query/.../max-bids/own` **(auth)** | The signed-in bidder's own standing Max Bids, with `state`. | SPEC-MAX-002, SPEC-MAX-003 |

Bid submission errors surface as structured validation errors (e.g. a `propertyName`/
`errorMessage` pair per field) — a client should render these directly rather than a generic
"bid failed" message, since the common case (amount below the current minimum) is
self-explanatory once shown.

## Taxonomy / Category browsing

| Call | Purpose | Spec refs |
|---|---|---|
| `GET /query/.../taxonomies?depth=2` | Top-level categories plus one level of children — the source for home screen category tiles and the qualifying-id set used to filter lots. | SPEC-CAT-001, SPEC-CAT-004 |
| `POST /search-engine/.../search/lots` with `assets/any(a: a/taxonomy/id eq '{id}')` OR'd per qualifying id, `filter`'d together with the Ending Soon clause, `orderBy: ["extendedEndDate asc", "endDate asc"]` | Category-filtered (or unfiltered) Ending Soon lots. | SPEC-CAT-004, SPEC-CAT-005 |

## Fulfillment (Sales Orders)

| Call | Purpose | Spec refs |
|---|---|---|
| `GET /query/.../cases/{id}` **(auth)** | Sales Order detail, including schema-driven structured sections. | SPEC-FUL-001, SPEC-FUL-004 |
| `POST /search-engine/.../cases` **(auth)** — filtered `type/name eq 'Sales Order'` | List the signed-in user's Sales Orders. | SPEC-FUL-001 |
| `GET /query/.../cases/{id}/comments` / `POST /support/.../cases/{id}/comments` **(auth)** | Fulfillment comment thread, paginated. | SPEC-FUL-003 |
| `POST /media/Files` **(auth)**, then `POST /support/.../cases/{id}/comments/{commentId}/media-items` | Attach a file to a comment: upload, then link. | SPEC-FUL-003 |

## Real-time

See `contracts/websocket-events.md` for the `publicAuctionEngineHub` contract (negotiate,
handshake, subscribe, `onHighestBidUpdate`).
