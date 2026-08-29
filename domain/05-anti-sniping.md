# Anti-Sniping (Extension)

## SPEC-EXT-001 — A late bid extends the deadline instead of ending the auction mid-contest

If a valid Bid lands within a defined window of a Lot's scheduled close, the Lot's Running
State transitions to `Extended`, and its effective closing time moves to a new
`extendedEndDate` rather than closing at the original `endDate`. This prevents a bidder from
"sniping" a win with a last-second bid no one else has a chance to respond to. The exact
trigger window (how close to closing a bid must land to extend) and the exact extension
length are backend-configured per Lot/Auction, not hardcoded client-side constants — a client
must read `extendedEndDate` from the server rather than compute it locally.

## SPEC-EXT-002 — Extension changes the applicable increment, not just the deadline

While a Lot is `Extended`, the minimum valid next Bid uses `extendedIncrementPrice`, not the
normal `incrementPrice` (`SPEC-BID-002`). This is a distinct, easy-to-miss consequence of
extension: a client that only reacts to the deadline change (updating the countdown) while
still suggesting/validating amounts against the pre-extension increment will produce a
suggested amount the server rejects. Any code path that computes "next minimum bid" must
branch on the *current* Running State on every computation, not once per page load.

## SPEC-EXT-003 — Extension can repeat

A Lot can be extended more than once if further late bids keep landing within the trigger
window of the *new* deadline. There is no fixed cap assumed at the client level — a client
must keep re-deriving the countdown target and applicable increment from the latest
`extendedEndDate`/Running State on every update, not assume "one extension only."

## SPEC-EXT-004 — Surface *why* the deadline moved, not just that it did

A user watching a countdown suddenly jump backward (more time added) with no explanation
reads as a bug. A client should show a short, visible explanation when a Lot is `Extended`
(e.g. "A bid arrived in the closing seconds, so the deadline was pushed back") rather than
silently changing the number — this is a case where explaining backend behavior in the UI is
part of correct behavior, not an optional nicety.

## SPEC-EXT-005 — Countdown display should degrade gracefully for long durations

A raw hour-count countdown (e.g. "1234:56:07") is unreadable for a Lot with days remaining.
Countdown displays should roll over into a `Nd HH:MM:SS` format once more than 24 hours
remain, switching to `HH:MM:SS` inside the final day. This is a presentation rule rather than
a business rule, but it is included here because both extension and closing-soon urgency are
communicated primarily through the countdown — getting its readability wrong undermines
`SPEC-EXT-004`.
