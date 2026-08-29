# Auction Lifecycle

## SPEC-AUC-001 — Visibility window vs. bidding window are separate

An Auction has four dates, not two:

- `visibleFrom` / `visibleUntil` — when the Auction (and its catalogue) can be browsed at all.
- `startDate` / `endDate` — the nominal bidding window.

A client **must not** assume "visible" implies "biddable." An Auction is commonly visible
(browsable, previewable) before `startDate`, so bidders can research Lots ahead of time, and
may remain visible after `endDate` for a period so results/history stay reachable. Whether
bidding is actually open is governed by each **Lot's own Running State** (below and in
`domain/02-lot-lifecycle.md`), not by the Auction's dates directly — an Auction's `startDate`/
`endDate` is the nominal envelope its Lots are scheduled within, but Extension (anti-sniping)
means individual Lots can run past `endDate`.

**Rule:** Never gate a "Place Bid" control on Auction dates. Gate it on the specific Lot's
Running State (`SPEC-BID-001`).

## SPEC-AUC-002 — Auction Type determines bidding transparency

Every Auction has a `type`. The type falls into one of two behavioral modes:

- **Open** — an ascending public auction. The current highest Bid amount, and typically the
  leading bidder's identity (masked — see `SPEC-BID-005`), are visible to all participants.
  Max Bids (`domain/04-max-bid-proxy-bidding.md`) are available.
- **Non-open** (sealed / negotiate-style) — competing Bid amounts and bidder identities are
  **not** disclosed to other participants. Max Bids do not apply: there is no "current
  highest" for the system to auto-bid against transparently.

**Rule:** A client must branch UI/behavior on Auction Type, not assume Open. Concretely:
public bidding-history and Max Bid controls must be hidden/disabled when the Lot's Auction is
not Open, rather than shown and left to fail server-side. A string match on the type name
containing "open" (case-insensitive) is an acceptable pattern for a client that hasn't been
handed a stronger discriminator, and one platform in this workspace already does this; the
canonical enum should still be pulled from the backend's own type list rather than
hardcoded, since new non-open subtypes can be added without client changes otherwise.

## SPEC-AUC-003 — Auction-level Running State is a rollup, not authoritative on its own

An Auction exposes its own live "Running State" and `extendedLotCount` as a convenience
rollup (e.g. for a "Live now" badge on a listing page). This is derived from its Lots, not
the other way around: a client rendering a specific Lot must fetch and trust that Lot's own
live data, never infer a Lot's biddability from the Auction-level rollup.

## SPEC-AUC-004 — Auctions belong to an organising company

Every Auction is run by an `organisingCompany` (the seller/operator), carrying a default
contact for buyer inquiries. This is display/contact metadata, not a bidding rule, but any
platform showing an Auction must surface who is running it and how to reach them — omitting
it is a support/trust gap, not a cosmetic one.
