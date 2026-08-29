# Max Bid (Proxy Bidding)

A Max Bid is a standing authorization: "automatically bid on my behalf, up to this ceiling,
as needed to stay leading." It exists only in **Open** auctions (`SPEC-AUC-002`) — there is no
disclosed "current highest" to auto-bid against in a sealed/negotiate auction.

## SPEC-MAX-001 — Placing a Max Bid can trigger an immediate server-side auto-bid

Setting a Max Bid is not "store this number for later." If the ceiling submitted is above the
Lot's current highest Bid, the backend may immediately place an actual counter-bid on the
bidder's behalf to reclaim the lead (up to that ceiling). A client must treat "Max Bid placed"
as an event that can have **immediately** changed the Lot's leading amount — it must re-fetch
live data and bidding history right after a successful Max Bid submission, exactly as it
would after placing a plain Bid. Do not assume a Max Bid is inert until some future bid from
someone else triggers it.

## SPEC-MAX-002 — Max Bid state vocabulary

A Max Bid carries a state distinct from the Lot's Running State. Observed values: `Active`
(currently in force — will auto-bid to defend the lead), `Paused`, `Ended`, `Won`. Treat this
as an open-ended, backend-owned vocabulary rather than a fixed enum a client exhaustively
switches on: render whatever state name the backend returns, and only special-case the ones
you have specific UI for (at minimum `Active`, since "is my max bid currently live" is a
common question), falling back to a generic badge for anything else. This keeps a client
from needing a synchronized release the moment the backend's state machine gains a value.

## SPEC-MAX-003 — "Leading" with a Max Bid means "ceiling still covers the current highest"

A bidder holding an **Active** Max Bid is considered leading when:

```
maxBid.amount >= lot.currentHighestBid   AND   maxBid.state == "Active"
```

This holds even if the bidder has no *plain* Bid recorded at that amount — the auto-bid
mechanism means their effective standing is their Max Bid ceiling, not a literal Bid row. A
client computing "is this user leading" (`SPEC-BID-006`) must check both an actual leading
Bid *and* an Active Max Bid whose ceiling still covers the current highest, and treat either
as sufficient. The reverse also holds: an Active Max Bid whose ceiling has been exceeded by
another bidder's Max Bid or plain Bid means the holder is **outbid**, and this must be
surfaced clearly (a warning, not silence) — "you set a max bid" is not the same information
as "your max bid is still winning."

## SPEC-MAX-004 — A Max Bid's own auto-bid may not always arrive as a distinct real-time push

Because a Max Bid's resulting counter-bid is server-triggered rather than a direct user
action on the viewing device, a client cannot assume the real-time channel (`domain/
06-real-time-updates.md`) will deliver it identically to a self-placed Bid's push in every
deployment topology. **After placing or updating a Max Bid, re-fetch live data and history via
a direct request rather than relying solely on the live-update socket** to reflect the
resulting state. This mirrors `SPEC-MAX-001` and is worth stating separately because it's
the mechanism *why* that rule exists.

## SPEC-MAX-005 — Max Bid ceilings are not disclosed to other bidders

Only the *effect* of a Max Bid (a resulting Bid amount, up to the ceiling) is visible to other
participants via the public bidding history. The ceiling itself is private to the bidder who
set it. A client must never render another bidder's Max Bid amount anywhere, including
indirectly (e.g. inferring and displaying "their ceiling is at least X" beyond what the
public highest-bid figure already reveals).
