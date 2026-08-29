# Real-Time Updates & Reconciliation

Both platforms consume a push channel that broadcasts the current highest bid for a Lot as it
changes (a SignalR hub, `publicAuctionEngineHub`, subscribed via `onHighestBidUpdate` — see
`contracts/websocket-events.md` for the wire contract). This document specifies the *client
behavior* required around that channel; it is arguably the highest-value section of this
whole spec, since a subtly wrong reconciliation rule produces a UI that quietly shows stale
or wrong prices rather than failing loudly.

## SPEC-RT-001 — A live push is a signal to refetch, not the sole source of truth

A push payload is sufficient to update the headline "current highest bid" figure, but a
client should treat it as a trigger to refresh the fuller picture from a direct REST call
(bidding history, the user's own bid/max-bid status, the Lot's full live-data object) rather
than trying to derive everything from the push payload alone. The push is optimized to be
small and frequent; REST is the authoritative, complete snapshot.

## SPEC-RT-002 — Never apply an update that regresses the leading amount

Pushes are not guaranteed to arrive in creation order (near-simultaneous bids handled by
different backend workers, or reordering in transit over a fallback transport). A client
must compare a candidate update's amount/timestamp against what it currently holds and
**discard the update if it would lower the displayed highest bid or use an older timestamp
than the current one held for that Lot.** Concretely: track the update's server-assigned
creation time per Lot, and only accept a new push if its creation time is not older than the
one already applied.

## SPEC-RT-003 — Reconcile push data against REST data by recency, not by source priority

A client that fetches live data via REST *and* receives pushes for the same Lot must decide,
for each field, which source is currently fresher — not hardcode "REST wins" or "push wins."
The correct rule: prefer whichever of (last REST fetch timestamp, last push's creation
timestamp) is more recent. This matters specifically because a Max Bid's resulting auto-bid
(`SPEC-MAX-004`) may reach the client via REST before — or instead of — a push, so blindly
preferring "the socket" as more authoritative than "the last fetch" can leave a client
showing a stale amount even while a fresher, correct number is sitting in a value it already
fetched moments earlier.

## SPEC-RT-004 — Your own successful action is a hard floor until the backend confirms it

The instant a client's own Bid or Max Bid submission succeeds, the client knows the true
leading amount is now **at least** that amount — even before any push or refetch confirms it,
and even if an immediately-following REST read races the write and returns a moment-stale
lower figure (an eventually-consistent read model lagging the write is expected, not a bug
to route around). Hold the just-placed amount as a local floor: display
`max(freshestKnownAmount, myJustPlacedAmount)` until a subsequent fetch or push actually
reports an amount `>=` it, then drop the floor and trust the fetched data normally again.
Skipping this floor produces a visible, confusing regression: the user sees their own
successful bid, then watches the number drop back down for a few seconds while the read side
catches up.

## SPEC-RT-005 — Surface connection health, don't fail silently

A client should expose (at least in a diagnostic/debug surface, ideally in the main UI too)
whether the live-update channel is actually connected — and "connected" must mean the
subscription handshake completed, not merely that a socket opened. A socket can open
successfully and then have its subscription rejected or silently dropped; reporting
"connected" from the mere fact of a successful `open` event produces a status indicator that
briefly lies. Reconnect automatically on an unexpected drop, with a short fixed or
lightly-backed-off delay (a few seconds is reasonable), for as long as something on screen
still cares about that Lot's updates — and stop reconnecting once nothing does, rather than
leaking a connection for a screen the user has left.

## SPEC-RT-006 — Treat the wire payload as versioned, not assumed

The push payload's exact shape (field names, nesting) is defined in
`contracts/websocket-events.md` and should be treated the same way as any other API contract
in `SPEC-AUTH`/backend-schema terms: decode defensively, and a field this spec doesn't
mention or a value with an unrecognized shape should be logged and dropped, not crash the
update pipeline for every other, correctly-shaped Lot update arriving on the same channel.
