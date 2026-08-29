# Platform Notes: bidding-app (iOS)

Stack: SwiftUI, `@Observable` state, MSAL for Azure AD B2C, a hand-rolled
`URLSessionWebSocketTask`-based client speaking the SignalR JSON protocol directly
(`LiveBidUpdateService.swift`), with an explicit long-polling fallback transport.

_As of this spec's initial version (`v0.1.0`), assessed against the codebase at the time this
repo was created:_

## Conforms well — this is currently the stronger reference implementation for real-time reconciliation

`LotBiddingCard.swift` and `LiveBidUpdateClient` implement the most complete version of
`domain/06-real-time-updates.md` seen in either codebase, and are worth treating as the model
to bring `bidding-web` up to when addressing its gaps above:

- **SPEC-RT-002** — `handleInvocation` explicitly discards a push whose `createdAt` is older
  than the currently-held one per Lot.
- **SPEC-RT-003** — `usesLiveUpdate` compares the push's `createdAt` against the last REST
  fetch timestamp (`liveDataFetchedAt`) to decide which is fresher, rather than assuming the
  socket always wins.
- **SPEC-RT-004** — `myPendingBidAmount` is exactly the local-floor pattern this spec
  describes: held after a successful bid, cleared only once a fetch confirms an amount at or
  above it.
- **SPEC-RT-005** — `isConnected` is only set true after the handshake response is parsed
  *and* the subscribe invocation is sent, not on the socket's mere `open`. Connection
  errors capture the actual WebSocket close code/reason via a delegate, and a non-101
  upgrade response is distinguished from a generic failure.
- **SPEC-BID-002/SPEC-EXT-002** — `effectiveIncrementPrice` branches on the live (not cached)
  running state.
- **SPEC-AUTH-003** — bearer token is sent via the `Authorization` header on the WebSocket
  upgrade request, explicitly not the query string (documented in-line as a deliberate
  choice); the long-polling transport also documents choosing headers over query params for
  the same reason.
- **SPEC-MAX-001/SPEC-MAX-004** — `placeMaxBid()` refetches live data and history
  immediately after a successful submission, with an explicit comment about why the socket
  alone isn't trusted for this.
- **SPEC-AUC-002** — `isOpenAuction` gates both the Max Bid button and the history section.
- **SPEC-MAX-002** — `MyBidsView`'s dashboard deliberately treats `state.name` as an
  open-ended, backend-owned vocabulary (`stateBreakdown`) rather than hardcoding expected
  values — the pattern this spec recommends in SPEC-MAX-002.

## Gaps / deviations to track

- **SPEC-FUL-001..004 (Sales Orders / fulfillment) are not implemented at all.** There is no
  screen analogous to `bidding-web`'s `MySalesOrders`/`SalesOrderDetails`. A signed-in
  bidder who wins a Lot on iOS currently has no way to see their Sales Order, its status, or
  communicate with the seller. This is the largest cross-platform gap identified while
  building this spec — treat `bidding-web`'s implementation (see `platform-notes/web.md`) as
  the reference to port, and the endpoints in `contracts/rest-api-surface.md`'s Fulfillment
  section as the API surface to build against.
- **SPEC-RES-003 (Buy Now)** — `priceRow` displays `buyNowPrice` as plain text, consistent
  with the spec's current display-only status; no action wired, same as web.
- No dedicated UI surfaces reserve-met/not-met wording beyond the `reservePriceBadge` capsule
  — this is fine (SPEC-RES-001 is satisfied), noted only so a reviewer knows it was checked.
