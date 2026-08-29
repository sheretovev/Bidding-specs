# Conformance Checklist

Run through this before shipping bidding-related changes on any platform. Each item links a
spec ID — cite it in your PR description when you check it off, so a reviewer (or a future
audit) doesn't have to re-derive why the item matters. This complements, and does not
replace, `conformance/scenarios.feature` — the checklist is "did we think about this," the
scenarios are "does it actually behave this way."

## Lot state & bidding gate

- [ ] Bid/Max Bid controls are enabled only when the Lot's *freshly fetched or reconciled*
      Running State is `Running` or `Extended`. (SPEC-LOT-002, SPEC-BID-001)
- [ ] An unrecognized Running State value disables bidding rather than defaulting to enabled.
      (SPEC-LOT-003)
- [ ] Every "next minimum bid" computation reads the *current* Running State to pick
      `incrementPrice` vs `extendedIncrementPrice` — not a value cached at page load.
      (SPEC-BID-002, SPEC-EXT-002)
- [ ] Countdown and "has this closed" logic prefer `extendedEndDate` over `endDate` whenever
      the former is present. (SPEC-LOT-004)
- [ ] Countdown display rolls hours into days past 24h remaining. (SPEC-EXT-005)

## Bid placement

- [ ] Submit control is disabled while a submission is in flight (no double-submit).
      (SPEC-BID-004)
- [ ] A failed submission preserves the typed amount; a successful one clears it.
      (SPEC-BID-004)
- [ ] Server-side validation errors are shown to the user, not swallowed behind a generic
      failure message. (contracts/rest-api-surface.md)
- [ ] Placing a Bid and placing a Max Bid are distinct, explicitly-chosen actions — neither
      silently substitutes for the other. (SPEC-BID-007)

## Max Bid

- [ ] After a successful Max Bid submission, live data and history are re-fetched
      immediately (not left to the live-update socket alone). (SPEC-MAX-001, SPEC-MAX-004)
- [ ] "Am I leading" accounts for an Active Max Bid whose ceiling still covers the current
      highest, not only a literal leading plain Bid. (SPEC-MAX-003, SPEC-BID-006)
- [ ] An outbid Active Max Bid is surfaced as a clear warning, not left silent.
      (SPEC-MAX-003)
- [ ] Max Bid controls are hidden/disabled for non-Open auctions. (SPEC-AUC-002)
- [ ] No other bidder's Max Bid ceiling is ever rendered. (SPEC-MAX-005)

## Real-time updates

- [ ] Bearer token on the live-update connection request travels as a header, never in the
      URL. (SPEC-AUTH-003)
- [ ] "Connected" status reflects a completed subscribe handshake, not just a socket open.
      (SPEC-RT-005)
- [ ] Incoming updates older (by server timestamp) than the currently-held one for that Lot
      are discarded, never applied. (SPEC-RT-002)
- [ ] Reconciliation between REST and push data picks whichever is more recent by timestamp,
      not a hardcoded "socket always wins." (SPEC-RT-003)
- [ ] A just-placed own Bid/Max Bid is held as a display floor until a fetch/push confirms an
      amount at or above it. (SPEC-RT-004)
- [ ] Reconnect logic exists for an unexpected drop, and stops once nothing on screen needs
      updates for that Lot anymore. (SPEC-RT-005)
- [ ] On reconnect, live data for on-screen Lots is refetched (missed pushes are not
      replayed by the channel).

## Reserve & Buy Now

- [ ] Reserve price figure itself is never displayed or inferrable — only the met/not-met
      boolean. (SPEC-RES-001)
- [ ] `isReservedPriceMet` never gates or disables bidding controls. (SPEC-RES-002)
- [ ] `buyNowPrice` is shown as informational only, not as an actionable control, until
      SPEC-RES-003's open question is resolved via an ADR. (SPEC-RES-003)

## Identity & data exposure

- [ ] Browsing and (Open-auction) bidding history work without sign-in; a sign-in prompt
      appears only at the point a gated action is attempted. (SPEC-AUTH-001)
- [ ] Other bidders' identities in bidding history are masked; the viewer's own row is
      clearly marked. (SPEC-BID-005)
- [ ] A failed/absent token degrades the affected action only, not the whole screen.
      (SPEC-AUTH-004)

## Fulfillment (if implementing this platform's winning-bidder journey)

- [ ] A winning bidder has a path to view their Sales Order(s). (SPEC-FUL-001)
- [ ] Sales Order structured sections render generically off their schema, not a hardcoded
      field list. (SPEC-FUL-004)
- [ ] Comment attachments render inline for images, as a labeled link otherwise, and history
      is paginated. (SPEC-FUL-003)

## Currency & tenancy

- [ ] Every amount is rendered with the currency from the *same record*, never a hardcoded
      default. (SPEC-I18N-002)
- [ ] Any aggregate/sum across records checks they share a currency before summing.
      (SPEC-I18N-002)
