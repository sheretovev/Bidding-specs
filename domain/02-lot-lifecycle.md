# Lot Lifecycle: Running State

A Lot's **Running State** is the single source of truth for whether it can currently accept
Bids. Both existing platforms already converge on the same four states, which this spec
adopts as canonical:

```
Not Running  ──(start reached)──>  Running  ──(bid lands near close)──>  Extended
                                       │                                     │
                                       └────────────(close reached)─────────┴──> Finished
```

## SPEC-LOT-001 — State definitions

| State | Meaning | Accepts Bids? |
|---|---|---|
| `Not Running` | Before the Lot's bidding window opens. | No |
| `Running` | Bidding is open; normal increment applies. | Yes |
| `Extended` | Bidding is open; the closing deadline has been pushed back by the anti-sniping rule (`domain/05-anti-sniping.md`), and the **extended** increment applies. | Yes |
| `Finished` | Bidding is closed. No further Bids or Max Bids are accepted. | No |

A fifth state, `Paused`, appears in at least one platform's state-handling code (a defensive
branch, not confirmed as reachable in normal operation). Treat it as: bidding is not
currently accepted, same as `Not Running`, and — like any unrecognized state name a client
receives — fail closed (disable bidding) rather than defaulting to "accepts bids." See
`SPEC-LOT-003`.

## SPEC-LOT-002 — Gate every bid-placement control on Running State, fetched fresh

**Rule:** "Place Bid" and "Place Max Bid" controls must be enabled only when the Lot's
*current* Running State is `Running` or `Extended`. This must be checked against live data
fetched for that purpose (or a live push reconciled per `domain/06-real-time-updates.md`),
never against a value cached from an earlier page load — a Lot's state can change under the
user's feet while a screen is open, and submitting against a stale `Running` assumption
against a now-`Finished` Lot is a guaranteed, avoidable server rejection.

This is a client-side UX courtesy, not a security boundary: the backend independently
rejects out-of-window Bids regardless of what the client allowed the user to attempt. Both
checks are required — the client check so users get instant feedback instead of a round
trip; the server check because the client can never be trusted to enforce it.

## SPEC-LOT-003 — Unknown Running State values fail closed

A client must not hardcode an exhaustive switch that silently falls through to "biddable" for
any state name it doesn't recognize. New Running States (or a renamed existing one) must
default to **not accepting bids** and showing a generic "bidding isn't open" message, so a
backend-side vocabulary change degrades to "temporarily can't bid" rather than "silently
accepts a bid the backend will reject anyway" or worse, one it doesn't reject.

## SPEC-LOT-004 — A Lot's `endDate` is nominal; `extendedEndDate` (when present) is authoritative

Once a Lot has been `Extended` at least once, an `extendedEndDate` field carries the actual
current closing time, superseding `endDate` for both the countdown display and for deciding
"has this lot definitely closed." A client must prefer `extendedEndDate` over `endDate`
whenever the former is present, for every purpose: countdown timers, "closing soon" styling,
and any client-side closed/open inference.

## SPEC-LOT-005 — A Lot may bundle multiple Assets, priced as one unit

A Lot's pricing (starting bid, increment, buy-now, reserve) applies to the Lot as a whole,
regardless of how many Assets it bundles. Bidding, Max Bids, and fulfillment all operate at
Lot granularity — a client must not attempt to bid on, or report a winning outcome for, an
individual Asset within a multi-Asset Lot.
