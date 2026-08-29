# Reserve Price & Buy Now

## SPEC-RES-001 — Reserve price is disclosed only as a boolean, never as a figure

A Lot may carry an undisclosed reserve price — a minimum the seller requires before the sale
is binding. Bidding is not blocked below it. A client must only ever surface **whether the
reserve has been met** (`isReservedPriceMet: true/false`, or absent/unknown before any bid),
never the reserve figure itself, which is not exposed by the backend to bidder-facing clients
and must not be inferred, estimated, or displayed even as a range.

## SPEC-RES-002 — "Reserve met" is informational, not a gate

Meeting the reserve does not change whether a Bid can be placed, and does not end bidding by
itself — a Lot can continue accepting Bids after its reserve is met, right up to its normal
close (including any `Extended` window, `domain/05-anti-sniping.md`). Do not use
`isReservedPriceMet` to disable bidding controls or to imply the Lot is effectively over.

## SPEC-RES-003 — Buy Now: currently spec-only, not implemented by either platform

Lots carry a `buyNowPrice` field, and both `bidding-web` and `bidding-app` already **display**
it wherever pricing is shown. Neither platform, as of this spec's writing, exposes an actual
"buy it now" purchase action that would let a bidder win a Lot outright at that price and
skip competitive bidding — the field is shown for informational context only today.

This is recorded here deliberately as a **known gap**, not silently treated as "not part of
the spec": the presence of `buyNowPrice` in the domain model implies the intended behavior —
a bidder should be able to invoke a Buy Now action while a Lot is `Running` (not yet
`Extended`, since a bid war already in its extension window has arguably moved past a
"skip to the fixed price" moment — see the open question below) to win it immediately at that
price, closing the Lot and routing straight to `domain/08-post-auction-fulfillment.md`. Until
this is implemented, a client should not present `buyNowPrice` in a way that implies a bidder
can act on it (e.g. as a clickable button) — display it as a plain informational figure only.

**Open question for whichever platform implements this first, to resolve via an ADR here
before shipping divergently:** does Buy Now remain available once a competitive Bid already
exceeds it (it shouldn't — there is nothing left to "buy now" cheaper than the current
market), and is it available during `Extended`? Track the decision in `decisions/`, not
independently in each platform repo.
