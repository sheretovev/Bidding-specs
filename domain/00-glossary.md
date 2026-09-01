# Glossary

Canonical terms used throughout this spec. A platform's own code and UI copy may use
different display labels, but internal identifiers and docs should map onto these.

| Term | Meaning |
|---|---|
| **Auction** | A scheduled event with a start/end window that groups one or more Lots for bidding. Has an `Auction Type` (see `domain/01-auction-lifecycle.md`) and a visibility window distinct from its bidding window. |
| **Lot** | A single biddable item (or bundle of Assets) within an Auction. Has its own pricing (starting bid, increment, buy-now, reserve) and its own Running State — a Lot's bidding window can differ per-lot within the same Auction. |
| **Asset** | The underlying real-world item(s) a Lot represents (e.g. a vehicle, a property). A Lot may bundle multiple Assets. |
| **Taxonomy / Category** | A node in the hierarchical classification tree Assets are tagged with (e.g. "Vehicles" → "Trucks"). Used as the home screen's browsing categories — see `domain/11-home-category-browsing.md`. Otherwise, general asset cataloguing is out of scope for this spec. |
| **Icon Name** | An abstract, platform-agnostic string a Taxonomy node's `icon` field carries (e.g. `"helicopter"`), mapped to an actual glyph independently by each platform. See `contracts/taxonomy-icon-map.md`. |
| **Bid** | A single, standing offer placed by a Bidder on a Lot for a specific amount. Bids are ascending-only: a new Bid must exceed the current highest by at least the applicable increment. |
| **Max Bid** (proxy bid) | A ceiling amount a Bidder authorizes the system to bid up to, automatically, on their behalf as competing Bids arrive. See `domain/04-max-bid-proxy-bidding.md`. |
| **Highest Bid / Leading Bid** | The current winning Bid amount on a Lot at a point in time. |
| **Bidder** | An authenticated user (Contact), optionally acting on behalf of a Company, placing Bids. |
| **Running State** | A Lot's (and, in aggregate, an Auction's) live bidding-window status: `Not Running` → `Running` → (`Extended`)* → `Finished`. See `domain/02-lot-lifecycle.md`. This is distinct from a Lot/Auction's publication `State` (draft/published/archived — an admin/back-office concern, not a bidder-facing one, and out of scope here). |
| **Increment** | The minimum amount by which a new Bid must exceed the current Highest Bid. Two increments exist per Lot: the normal `incrementPrice`, and `extendedIncrementPrice`, which applies only while the Lot is `Extended`. See `domain/03-bidding-rules.md`. |
| **Extension / Anti-Sniping** | The rule that a Bid landing near a Lot's closing time pushes the deadline back rather than letting the Lot close mid-bid-war. See `domain/05-anti-sniping.md`. |
| **Reserve Price** | An optional undisclosed minimum a Lot must reach before its sale is binding. Bidding continues below it; `Reserve Met` is a boolean signal, not a price. See `domain/07-reserve-price-and-buy-now.md`. |
| **Buy Now Price** | An optional fixed price at which a Lot could be won outright, bypassing competitive bidding. **Currently spec-only** — see `domain/07-reserve-price-and-buy-now.md` for status. |
| **Open Auction** | An Auction Type where Bid amounts and the identity of the current leader are visible to all participants (an ascending public auction). |
| **Non-Open Auction** (sealed / negotiate) | An Auction Type where competing Bids are not disclosed. Max Bids and public bidding-history are not applicable in this mode. |
| **Sales Order** (post-auction case) | The fulfillment record created once a Lot is won, tracking payment/logistics/communication between the winning Bidder and the seller. See `domain/08-post-auction-fulfillment.md`. |
| **Public Environment** | A named, API-key-scoped tenant/storefront (e.g. `auction_website`) that a client authenticates its *anonymous* traffic against, distinct from a signed-in user's identity. See `domain/09-identity-and-access.md`. |

## Spec ID prefixes

Rules in `domain/*.md` are numbered as `SPEC-<AREA>-<NNN>`. Areas in use:

| Prefix | Area |
|---|---|
| `SPEC-AUC` | Auction lifecycle |
| `SPEC-LOT` | Lot lifecycle |
| `SPEC-BID` | Bid placement & validation |
| `SPEC-MAX` | Max bid / proxy bidding |
| `SPEC-EXT` | Anti-sniping / extension |
| `SPEC-RT`  | Real-time update delivery & reconciliation |
| `SPEC-RES` | Reserve price & buy now |
| `SPEC-FUL` | Post-auction fulfillment |
| `SPEC-AUTH` | Identity & access |
| `SPEC-I18N` | Currency & multi-tenancy |
| `SPEC-CAT` | Home category browsing |
