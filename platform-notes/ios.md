# Platform Notes: bidding-app (iOS)

Stack: SwiftUI, `@Observable` state, MSAL for Azure AD B2C, a hand-rolled
`URLSessionWebSocketTask`-based client speaking the SignalR JSON protocol directly
(`LiveBidUpdateService.swift`), with an explicit long-polling fallback transport.

**See [`conformance/audit-2026-08-31.md`](../conformance/audit-2026-08-31.md) for the full,
verified rule-by-rule status (a complete code read, not a sample) — this file is a summary
of it, not an independent source.**

## Conforms well — still the reference implementation for real-time reconciliation, lifecycle gating, and anti-sniping

`LotBiddingCard.swift` and `LiveBidUpdateClient` implement the most complete version of
`domain/06-real-time-updates.md` seen in either codebase, and `canBid`/`bidUnavailableReason`
are the reference for `domain/02-lot-lifecycle.md`'s gating rules — `bidding-web` should port
both wholesale rather than reinvent them:

- **SPEC-LOT-002/003, SPEC-BID-001** — `canBid` gates on the live Running State fetched
  fresh, and fails closed for any unrecognized state (including via a generic
  `bidUnavailableReason` message).
- **SPEC-RT-002/003/004/005** — timestamp-based regression protection, REST-vs-push recency
  reconciliation (`usesLiveUpdate`), the own-action floor (`myPendingBidAmount`), and an
  honestly-gated `isConnected` (true only after handshake + subscribe succeed) are all
  correctly implemented.
- **SPEC-BID-002/SPEC-EXT-002** — `effectiveIncrementPrice` branches on live running state.
- **SPEC-AUTH-001/002/003/004** — anonymous browsing works throughout; only `MyBidsView` is
  sign-in gated; MSAL/Azure AD B2C wired correctly; bearer token never leaves the
  `Authorization` header, including on the WebSocket upgrade; a missing/failed token
  degrades gracefully everywhere except the (correctly) gated screens.
- **SPEC-MAX-001/004, SPEC-AUC-002** — Max Bid refetches live data/history directly after
  success; `isOpenAuction` correctly gates both the Max Bid button and the history section.

## Gaps / deviations to track

Ranked by severity — see the audit's punch list for the cross-platform priority order.

- **SPEC-BID-005/SPEC-AUTH-005 — no bidder-identity masking at all.** `LotBiddingCard
  .historyRow` renders every other bidder's full name/company name verbatim; there is no
  masking logic anywhere in the app. This is a real privacy gap, not a cosmetic one — port
  `bidding-web`'s `maskUsername` pattern from `BiddingHistory.jsx`.
- **SPEC-MAX-003 — max-bid leading/outbid status is never computed.** Nothing compares an
  `OwnMaxBid`'s amount/state against the lot's current highest; `MyBidsView` always passes
  `isLeading: nil` for the Max Bids segment, and `LotBiddingCard.isLeadingBidMine` never
  consults the user's own max bid either. A user relying on proxy bidding has no way to see
  whether it's currently winning. Port `bidding-web`'s `LotBidding.isLeading()` logic.
- **SPEC-FUL-001..004 — Sales Orders / fulfillment are not implemented at all,** confirmed
  absent (not just unbuilt) by an exhaustive search. A signed-in bidder who wins a Lot on iOS
  has no way to see their Sales Order, its status, or communicate with the seller. Treat
  `bidding-web`'s implementation as the reference to port; note this app already has the
  reusable building block for SPEC-FUL-004's schema-driven rendering (`StructuredDataView`),
  just not wired to a fulfillment endpoint.
- **SPEC-I18N-002 — hardcoded `"USD"` currency fallback** across 6 production call sites
  (`LotBiddingCard`, `PublicLotsView`, `AuctionDetailView`), and a currency-unsafe sum in
  `MyBidsView`'s "Committed while leading" stat tile (sums across currencies before checking
  they match, same bug shape as `bidding-web`'s dashboard).
- **Reconnect-triggered refetch is missing.** No code reacts to the live-update connection
  transitioning from disconnected back to connected — a drop relies on the next natural push
  or a manual pull-to-refresh to catch up on whatever was missed while disconnected.

## Features present but not yet covered by the spec

Flagged during the audit as real, working functionality with no corresponding domain rule —
worth a deliberate "extend the spec" or "explicitly out of scope" decision rather than
leaving unowned: live-update transport switching (WebSocket/long-polling, user-facing in
Profile), the in-app Network Debug inspector, decode-drop transparency banners
(`DecodeWarningBanner`), faceted asset/lot filtering, and multi-backend-environment
switching (Dev/Test/Integration — distinct from the Public Environment tenancy concept in
`domain/10-currency-and-multi-tenancy.md`).
