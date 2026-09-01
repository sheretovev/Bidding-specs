# 3. Home category browsing: subtree matching and section order

## Status

Accepted

## Context

The home screen's category tiles need two judgment calls the raw feature request didn't
settle on its own, and neither platform's existing code contains a working precedent to
just copy (`bidding-web`'s `CategoriesDropdown` treats a parent category and its
subcategories as independent, non-overlapping exact-match filters when navigating to the
Assets page; neither platform's home screen had a category-filtered Ending Soon list at
all before this spec).

### 1. Does selecting a category include its subcategories?

A taxonomy is a tree (`GET /taxonomies?depth=2` returns top-level nodes with one level of
children). If a user selects a broad category like "Vehicles" and matching is exact-only,
a lot whose only tagged asset is under the child node "Trucks" would not appear — which
would read as a bug to anyone who doesn't already know the taxonomy is split that finely.
The ideal answer (walk the full subtree, arbitrary depth) requires the search index to
expose a filterable full taxonomy path on each asset *nested inside a lot's `assets`
array* — confirmed to exist on the standalone `Asset` detail DTO (`taxonomyPath`), but
**not confirmed** to exist on a lot's own nested per-asset search-index entries, and this
spec was written without live access to the backend to verify the search index's schema.

**Decision:** match a category's own id plus its already-fetched direct children's ids only
(one level), building an OR of `assets/any(a: a/taxonomy/id eq '{id}')` clauses — see
SPEC-CAT-004. This needs no unverified backend capability: the children are already in hand
from the same `/taxonomies?depth=2` call used to render the tiles. It doesn't handle a
taxonomy deeper than two levels, but it's a real improvement over exact-only matching and
ships without a backend-schema gamble.

**Revisit when:** someone confirms (via the search-engine's own field list, or by trying it
against a real environment) whether a full taxonomy path is filterable on a lot's nested
assets. If so, replace the OR-list with a single subtree-path filter and widen this to
arbitrary depth — update SPEC-CAT-004 and this ADR together rather than one silently
drifting from the other.

### 2. Category browsing vs. personalized bidding status — which comes first?

The feature request itself raised this as an open question rather than a settled
requirement ("maybe it makes sense to evaluate if that thing had to be first").

**Decision:** category tiles and the Ending Soon list they control come first, before any
"your active bids" content, for every visitor. Reasoning: an anonymous visitor — who a home
screen has to work for regardless, and who is a large fraction of traffic for a public
auction site — has no personalized content at all, so category-driven discovery is the only
thing home can do for them; making a signed-in visitor scroll past it to reach their own
bids would be a worse experience for the majority case to marginally improve the minority
case. A signed-in visitor's bidding activity remains a first-class, easy-to-reach part of the
home screen — just not gating what a category-focused visitor sees first.

## Consequences

- Home screen implementations on both platforms fetch taxonomy at `depth=2` and only ever
  need that response to build both the tile row and the qualifying-id set per tile — no
  second network call per category selection.
- If a taxonomy is deeper than two levels, a user selecting a top-level category will miss
  lots tagged only at grandchild depth or deeper. This is a known, accepted limitation of
  this decision, not an oversight — tracked here so it isn't rediscovered as a mystery bug.
- Any future work on "your active bids" home content should design around sitting below the
  category/Ending Soon section, not compete with it for the top slot.
