# Platform Notes: bidding-web

Stack: React (react-bootstrap), MSAL React for Azure AD B2C, a hand-rolled `WebSocket`
client speaking the SignalR JSON protocol directly (`src/context/WebSocketContext.jsx`).

This note is a living record of how `bidding-web` currently maps to this spec, kept here
(not scattered across code comments) so a spec change can be checked against a single
per-platform status. Update it whenever bidding-related code changes.

**See [`conformance/audit-2026-08-31.md`](../conformance/audit-2026-08-31.md) for the full,
verified rule-by-rule status (a complete code read, not a sample) — this file is a summary
of it, not an independent source.** An earlier version of this file, written from a partial
reading of the codebase, understated several gaps (notably SPEC-LOT-002/SPEC-BID-001, which
turned out to be entirely unimplemented, not just imperfect). Trust the audit file over any
older content here if the two ever disagree before this note is next refreshed.

## Conforms well

- `getNextBidAmount` (`src/utils/bidding.js`) correctly branches on `runningState ===
  "Extended"` to pick `extendedIncrementPrice` — implements SPEC-BID-002/SPEC-EXT-002.
- `LotDetails.jsx`/`LotCard.jsx` prefer `extendedEndDate` over `endDate` for the countdown —
  implements SPEC-LOT-004. Countdown formatting rolls into days past 24h (SPEC-EXT-005).
- Reserve price is only ever shown as a met/not-met check/cross icon, never a figure —
  implements SPEC-RES-001/002. Buy Now is display-only, consistent with SPEC-RES-003.
- "Leading" status (`LotBidding.jsx`'s `isLeading()`) correctly factors in an Active Max Bid
  whose ceiling still covers the current highest, not just a literal leading bid —
  implements SPEC-BID-006/SPEC-MAX-003. **This is currently the reference implementation
  `bidding-app` should port for its own SPEC-MAX-003 gap.**
- Sales Orders (`MySalesOrders.jsx`, `SalesOrderDetails.jsx`) implement SPEC-FUL-001..004,
  including schema-driven structured sections and a paginated, attachment-capable comment
  thread. **This remains the reference implementation for `domain/08-post-auction-
  fulfillment.md`.**

## Gaps / deviations to track

Ranked by severity — see the audit's punch list for the cross-platform priority order.

- **SPEC-LOT-002/003, SPEC-BID-001 — no client-side bid-window gate at all.**
  `LotBidding.jsx` never reads `runningState`; "Place Bid"/"Place Max Bid" are always
  enabled regardless of the lot's actual state. Only the backend rejects an invalid
  submission. This is the highest-priority fix identified for this platform — port
  `bidding-app`'s `LotBiddingCard.canBid` pattern.
- **SPEC-AUC-002 — no Auction Type branching anywhere.** Max Bid and public bidding history
  are shown unconditionally, on every auction type, including non-open/sealed ones where
  neither should apply. Port `bidding-app`'s `isOpenAuction` gate.
- **SPEC-RT-004 — `onBidSuccess` is dead code.** `LotBidding.jsx` defines the callback but no
  parent (`LotDetails.jsx`, `LotCard.jsx`, `PublicAuctionDetails.jsx`) ever passes it in. The
  own-action floor this spec requires does not exist — a user's own successful bid can still
  show a stale, lower "Highest Bid" until an external push arrives.
- **SPEC-MAX-001/004 — Max Bid never refetches live data.** `handleSubmitMaxBid` only
  refetches the user's own bid status, never the lot's live data or bidding history; a max
  bid's auto-bid effect is only reflected once (if) a WebSocket push happens to arrive.
- **SPEC-RT-002/003/005 — real-time reconciliation is weaker than iOS's.** Regression
  protection is amount-only (no server timestamp tracked at all); there's no REST-vs-push
  recency comparison; `isConnected` is set on socket-open (before the handshake completes)
  and is never surfaced in any UI, even for debugging.
- **SPEC-AUTH-001/004 — bidding history requires sign-in unconditionally.**
  `BiddingHistory.jsx` shows a login wall even for Open auctions, contradicting the spec's
  anonymous-browsing guarantee; a token failure there shows a generic error rather than
  degrading to anonymous.
- **SPEC-BID-005 — partial masking.** Other bidders' names are masked, but the viewer's own
  row in the shared history table is never marked as theirs (that distinction only exists
  separately, in `LotBidding.jsx`'s own bid-status card).
- **SPEC-EXT-004 — extension explanation is a hover-only tooltip** on the lot list card;
  the main `LotDetails` bidding screen has no explanation at all.
- **SPEC-I18N-002/003 — currency handling.** Hardcoded fallback currencies (`'AZN'`/`'BZD'`)
  appear across ~8 call sites instead of omitting the suffix; `UserDashboard.jsx`'s "Total
  Spend" sums bid amounts across currencies with no equality check and no currency label at
  all. Currency formatting is naive string concatenation as the default path, not just an
  unrecognized-code fallback.
- **SPEC-AUC-004 — organiser contact info** (email/phone) is not shown anywhere on the
  Auction screens; only the organiser's name is.
