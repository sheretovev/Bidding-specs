# Home Category Browsing

The home/landing screen is the primary discovery surface for a visitor who already knows
*what kind of thing* they want (a bidder interested in helicopters should never have to look
at tractors to get there) but not yet *which specific lot*. This section defines the
canonical behavior: category tiles sourced from taxonomy, each acting as a live filter on an
"Ending Soon" list — not a separate browse-everything catalogue.

**Neither platform fully implements this today.** `bidding-web`'s home page has a correct
"Ending Soon" query but no category filter on it; `bidding-app`'s home tab has neither a
category tile row nor an Ending Soon list at all (only aggregate stat tiles and a bar chart).
This spec defines the target both should converge on. See `decisions/0003-home-category-
browsing.md` for the two judgment calls made while writing it.

## SPEC-CAT-001 — A Category is a Taxonomy node

The home screen's categories are taxonomy nodes fetched from the taxonomy tree (`GET
/query/public-api/{env}/taxonomies?depth=2` — already used by `bidding-web`'s
`CategoriesDropdown`, just not visually on the home screen). A category tile renders a
taxonomy node's `title` and its `icon` (see SPEC-CAT-002). Home shows the **top-level**
nodes as tiles; the immediate children fetched alongside them are not shown as separate
tiles on the home screen, but do participate in filtering (SPEC-CAT-004).

## SPEC-CAT-002 — Icon representation: an abstract name, mapped per platform, with a mandatory fallback

A taxonomy's `icon` field is an optional, platform-agnostic **name string** (e.g.
`"helicopter"`, `"tractor"`) — not a glyph, font reference, or image URL. Each platform owns
a small lookup table mapping these names to its own design system's icon (a `react-icons`
component for web, an SF Symbol name for iOS). The shared vocabulary of names both tables
key on is published in `contracts/taxonomy-icon-map.md` so the two platforms' tables stay in
sync — adding a category icon that renders on web but not iOS (or vice versa) is exactly the
kind of drift this spec exists to prevent.

**Rule:** if a taxonomy node's `icon` is absent, empty, or not found in the platform's
lookup table, render a single, consistent default category glyph instead — never omit the
icon slot, break the tile's layout, or show a placeholder broken-image glyph. An unmapped
icon name is expected and normal (taxonomies get new categories over time; the mapping table
lags), not an error condition.

## SPEC-CAT-003 — Selecting a category is a filter, not navigation to a new browsing mode

Tapping/clicking a category tile does not leave the home screen or replace it with a generic
"browse this category's assets" page (that experience already exists separately — see
`bidding-web`'s `CategoriesDropdown` → Assets page flow, which SPEC-CAT-003 through 005 do
not change). It re-scopes the home screen's own **Ending Soon** list (SPEC-CAT-005) to lots
qualifying for that category, in place, so a signed-out visitor who only cares about one
category never has to see lots outside it. Selecting the same category again, or an explicit
"All categories" control, clears the filter back to the unfiltered Ending Soon list.

## SPEC-CAT-004 — Qualifying rule: at least one asset in the lot matches the category

A Lot qualifies for a selected category if **at least one of its Assets belongs to that
taxonomy node, or to one of that node's direct children** (the children already fetched
alongside the top-level nodes at `depth=2`, per SPEC-CAT-001 — not an arbitrary-depth
subtree walk, since the search index's per-lot asset entries are not confirmed to expose a
filterable full taxonomy path; see `decisions/0003-home-category-browsing.md`). Concretely,
the filter is an OR of an "any asset in this lot has this exact taxonomy id" clause per id in
{selected category} ∪ {its fetched direct children}:

```
assets/any(a: a/taxonomy/id eq '{id-1}') or assets/any(a: a/taxonomy/id eq '{id-2}') or ...
```

This `assets/any(...)` lambda form is the proven, already-used pattern for "a lot has at
least one asset matching X" (`bidding-app`'s `odataAssetAnyEquals`, already applied to
`type/name`, `location/name`, `make/name`, `model/name` on the Lots search). Extend it to
`taxonomy/id`, don't invent a parallel mechanism.

## SPEC-CAT-005 — The "Ending Soon" query is canonical and shared

Whether or not a category is selected, the list beneath the category tiles is governed by
one query, already correctly implemented in `bidding-web`'s `HomePage.jsx` and to be ported
to `bidding-app` verbatim (not reinvented):

- **Only** lots currently `Running` or `Extended` qualify — never `Not Running` or
  `Finished`.
- **Only** lots that haven't actually closed yet: `extendedEndDate` in the future when
  present, else `endDate` in the future.
- **Sorted ascending** by `extendedEndDate` (falling back to `endDate` when null) — soonest
  to close first. This is the single most important ordering decision on the home screen:
  it is what makes "ending soon" mean "closing".

As an OData filter/orderBy pair (values illustrative):

```
filter:  (runningState/name eq 'Running' or runningState/name eq 'Extended')
         and (extendedEndDate ge {now} or (extendedEndDate eq null and endDate ge {now}))
         [and (category clause from SPEC-CAT-004, when a category is selected)]
orderBy: ["extendedEndDate asc", "endDate asc"]
```

## SPEC-CAT-006 — Home screen section order

Category tiles and the Ending Soon list they control sit **above** any personalized
bidding-status content (a signed-in user's active/leading bids), for every visitor —
signed-in or not. See `decisions/0003-home-category-browsing.md` for why category-driven
discovery is treated as the home screen's primary job rather than personalized status.
