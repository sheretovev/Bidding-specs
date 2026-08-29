# Post-Auction Fulfillment (Sales Orders)

## SPEC-FUL-001 — Winning a Lot creates a fulfillment record ("Sales Order")

Once a Lot closes with a winning Bid, a fulfillment record is created linking the winning
Bidder, the Lot/Auction, and the total amount. This record is a case-like entity ("Sales
Order") that carries its own state (e.g. pending payment, in progress, completed — treat as
an open backend-owned vocabulary, same guidance as `SPEC-MAX-002`), supports threaded
comments with file attachments between the bidder and the seller/operator, and can carry
additional structured data specific to the sale (e.g. logistics fields) beyond the bid
amount itself.

This is currently implemented in `bidding-web` only (`MySalesOrders`/`SalesOrderDetails`) and
is a **known cross-platform gap**, not an intentional web-only feature — see
`platform-notes/ios.md`. Any platform letting a user win a Lot must give them a way to see
what happens next; a platform without this screen is, from the spec's perspective,
incomplete for the winning-bidder journey, even if bidding itself works.

## SPEC-FUL-002 — A Sales Order references its origin Lot/Auction, not just an Asset

Because a Lot can bundle multiple Assets (`SPEC-LOT-005`), a Sales Order's link back to "what
was won" must be by Lot (and, transitively, Auction), with the Asset(s) as a further detail —
not solely by Asset, which would be ambiguous or incomplete for a multi-Asset Lot.

## SPEC-FUL-003 — Comment threads support attachments, and must handle both directions

The bidder and the seller/operator communicate via a comment thread scoped to the Sales
Order. A client must support both posting a comment (optionally with one or more file
attachments, uploaded to the media store and then linked to the created comment) and
rendering the other party's comments, including their attachments, with images shown inline
and non-image files as a labeled download/open link. Comment history should be paginated
rather than loaded in full, since a long-running fulfillment can accumulate many messages.

## SPEC-FUL-004 — A Sales Order's structured data is schema-driven, not hardcoded per field

Beyond the bid-derived fields (lot, auction, amount, currency), a Sales Order can carry
additional structured sections whose shape (field names, types, single-vs-repeating) is
defined by a schema attached to the record rather than known in advance by the client. A
client must render these generically off the schema (label + formatted value, with
repeating sections as a table) rather than hardcoding a fixed set of expected fields — this
is what lets the backend add new post-sale data requirements (e.g. a new logistics field)
without requiring a client release.
