# Platform Notes: bidding-web

Stack: React (react-bootstrap), MSAL React for Azure AD B2C, a hand-rolled `WebSocket`
client speaking the SignalR JSON protocol directly (`src/context/WebSocketContext.jsx`).

This note is a living record of how `bidding-web` currently maps to this spec, kept here
(not scattered across code comments) so a spec change can be checked against a single
per-platform status. Update it whenever bidding-related code changes.

_As of this spec's initial version (`v0.1.0`), assessed against the codebase at the time this
repo was created:_

## Conforms well

- `getNextBidAmount` (`src/utils/bidding.js`) correctly branches on `runningState ===
  "Extended"` to pick `extendedIncrementPrice` — implements SPEC-BID-002/SPEC-EXT-002.
- `LotLiveUpdate.jsx` explicitly rejects a push whose parsed amount is lower than the
  currently held one — implements SPEC-RT-002.
- `LotDetails.jsx`/`LotCard.jsx` prefer `extendedEndDate` over `endDate` for the countdown —
  implements SPEC-LOT-004.
- Countdown formatting rolls into days past 24h — implements SPEC-EXT-005.
- Bidding history masks other bidders (`maskUsername`, first 3 chars + `*`) — implements
  SPEC-BID-005.
- Reserve price is only ever shown as a met/not-met check/cross icon, never a figure —
  implements SPEC-RES-001/002.
- Sales Orders (`MySalesOrders.jsx`, `SalesOrderDetails.jsx`) implement SPEC-FUL-001..004,
  including schema-driven structured sections and a paginated, attachment-capable comment
  thread. **This is currently the reference implementation for `domain/08-post-auction-
  fulfillment.md`** — a future iOS (or other platform) implementation of fulfillment should
  use this as the closest existing example of the intended behavior, alongside the spec text.

## Gaps / deviations to track

- **SPEC-RT-004 (own-action floor) is not implemented.** `LotBidding.jsx` re-fetches the
  user's bid status after a successful submission, but does not hold the just-submitted
  amount as a local floor against a stale intervening fetch — a brief regression is possible.
  Worth porting the pattern `bidding-app`'s `LotBiddingCard.swift` already uses
  (`myPendingBidAmount`).
- **SPEC-RT-005 (honest "connected" status)** — `WebSocketContext.jsx` sets `isConnected`
  on the socket's `onopen`, before the SignalR handshake/subscribe messages are confirmed
  accepted. This can report "connected" slightly before the subscription is actually live.
  Low practical impact today, but worth aligning with `bidding-app`'s stricter definition.
- **SPEC-MAX-002 (open-ended state vocabulary)** — `MyMaxBids.jsx`'s `getStateBadge` and
  `getRunningStateBadge` hardcode a fixed map (`Active/Paused/Ended/Won` and
  `Not Running/Running/Extended/Finished/Paused`) with a generic fallback for anything else.
  This is acceptable per the spec (a fallback exists), but note it as the source this spec's
  "known observed values" lists were drawn from — if the backend's vocabulary changes, this
  is the first place a mismatch would show up as an unstyled fallback badge, not a bug.
- **Buy Now (SPEC-RES-003)** is display-only, consistent with the spec's current status —
  `buyNowPrice` appears in `LotDetails.jsx`/`LotCard.jsx` as plain text, not a control.
- No explicit reconnect-triggered refetch of on-screen Lots was found beyond the socket's own
  5-second reconnect timer — confirm on-screen Lot data is refreshed after a reconnect, not
  just the socket subscription being re-established silently.
