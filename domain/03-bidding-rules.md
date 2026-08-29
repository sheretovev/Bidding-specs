# Bidding Rules

## SPEC-BID-001 — When a Bid may be placed

A Bid is only valid when the target Lot's Running State is `Running` or `Extended`
(`SPEC-LOT-002`). Both platforms must gate the bid UI on this and treat any other state as
non-biddable.

## SPEC-BID-002 — Minimum valid Bid amount

```
minimumNextBid = currentHighestBid (or startingBidPrice, if no Bid exists yet)
                 + applicableIncrement
```

Where `applicableIncrement` is:

- `lot.extendedIncrementPrice` while the Lot's Running State is `Extended` (falling back to
  `lot.incrementPrice` if no extended-specific increment is configured for that Lot), or
- `lot.incrementPrice` otherwise.

**This is the single rule most likely to be implemented incorrectly**, because it is easy to
compute the increment once (at page load, using whatever the Running State was then) and
never recompute it when the state transitions to `Extended` mid-session. A client must
recompute `minimumNextBid` from the *current* Running State every time it renders or
validates a suggested bid amount — including reactively, the moment a live update changes
either the highest bid or the running state (see `domain/06-real-time-updates.md`).

A client may (and should) pre-fill the bid-amount field with `minimumNextBid` as a
convenience default, but must never prevent a bidder from entering a higher amount.

## SPEC-BID-003 — Bids are strictly ascending; rejection is authoritative server-side

A submitted Bid amount must be `>= minimumNextBid` at submission time on the server. A
client performing its own pre-submission check (recommended, for instant feedback) must
still submit and surface whatever the server actually returns — the server's validation is
authoritative because the highest bid can change between the client's last fetch and the
submission landing (another bidder, or the bidder's own earlier Max Bid auto-bidding). Do not
suppress a server-side rejection by only trusting the client-side check.

## SPEC-BID-004 — A Bid submission is a single, idempotent-from-the-user's-perspective action

While a Bid submission is in flight, the client must disable the submit control to prevent a
duplicate submission from a double-tap/double-click. On failure, the amount the user typed
must be preserved (not cleared) so they can retry without re-entering it; on success, the
form should clear and the UI should immediately reflect the new leading amount rather than
waiting for the next live-update push (see `SPEC-RT-004` on treating one's own successful
action as a floor).

## SPEC-BID-005 — Bidder identity is partially masked in public bidding history

A Lot's bidding history is visible (in Open auctions, `SPEC-AUC-002`) to any authenticated
viewer, but the *other* bidders' identities are not shown in full — display only a masked
form (e.g. a truncated name) unless the row belongs to the viewing user themself, in which
case it should be clearly marked as theirs (e.g. "Yours"/"Leading"). Do not resolve or expose
another bidder's full name, contact, or company identity through the bidding-history surface.

## SPEC-BID-006 — "Leading" is a derived, not stored, concept from the client's perspective

Whether the viewing bidder is currently leading a Lot is computed by comparing their own
best known standing (their leading regular Bid, and/or an Active Max Bid amount) against the
Lot's current highest Bid — see `domain/04-max-bid-proxy-bidding.md` for the Max Bid half of
this comparison. A client must recompute this on every relevant update (own bid placed,
own max bid placed, live push received, page refresh) rather than caching a "you are
leading" flag past the moment the underlying numbers it was computed from change.

## SPEC-BID-007 — Placing a Bid does not require, and should not implicitly create, a Max Bid

Placing a plain Bid and placing a Max Bid (`domain/04-max-bid-proxy-bidding.md`) are two
distinct, independently-invoked actions on two distinct endpoints. A client must not conflate
them (e.g. by silently converting a bid to a max bid, or vice versa) — the bidder must
explicitly choose which they intend, since a Max Bid authorizes ongoing automatic bidding on
their behalf and a plain Bid does not.
