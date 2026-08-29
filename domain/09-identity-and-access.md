# Identity & Access

## SPEC-AUTH-001 — Browsing is anonymous; bidding requires sign-in

Auction/Lot browsing, catalogue search, and (for Open auctions) public bidding history are
available without authentication, gated only by the Public Environment API key
(`SPEC-I18N-001`). Placing a Bid, placing a Max Bid, viewing "my bids"/"my max bids," and
anything under Sales Orders (`domain/08-post-auction-fulfillment.md`) requires a signed-in
identity. A client must present a clear, low-friction sign-in prompt at the point a bidder
attempts a gated action, rather than hiding the action entirely or failing with a raw 401.

## SPEC-AUTH-002 — Identity provider: Azure AD B2C via MSAL

Both platforms authenticate bidders against the same Azure AD B2C tenant via the MSAL family
of SDKs. A new platform should do the same rather than introducing a second identity system
— splitting identity per platform would mean a bidder's account, bid history, and standing
Max Bids don't follow them across web and mobile, which defeats the point of a shared
backend. Tokens are acquired silently when a valid session exists and refreshed transparently;
an interactive sign-in is only triggered when silent acquisition fails.

## SPEC-AUTH-003 — Bearer tokens never travel in a URL

An acquired access token is sent as an `Authorization: Bearer <token>` header on every
authenticated call, including the real-time channel's connection request where the transport
supports it. It must never be placed in a query string or URL path component, since URLs are
commonly captured in proxy/server access logs — this applies even to the live-update
WebSocket upgrade request, which is easy to overlook as "just a connection," not "a request
that gets logged like any other."

## SPEC-AUTH-004 — A missing/failed token means anonymous, not broken

If a bidder is not signed in, or silent token refresh fails, a client must fall back to
anonymous, API-key-only access for everything that supports it (browsing, public history),
and only surface an actual error for the specific actions that require authentication. A
transient token failure must not take down an otherwise-anonymous-capable screen.

## SPEC-AUTH-005 — Sensitive personal data is minimized in client-visible payloads

Other bidders' full identities are not resolved client-side even when an endpoint returns a
contact/company reference — see `SPEC-BID-005` and `SPEC-MAX-005`. A client must not attempt
to enrich a masked or reference-only identity by cross-referencing other endpoints it happens
to have access to.
