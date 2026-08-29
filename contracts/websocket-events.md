# Real-Time Channel Contract

Backend: PurpleUnity auction-engine's SignalR hub, `publicAuctionEngineHub`. Both platforms
implement the client side of this from scratch (no official SignalR Swift SDK exists; the web
client also speaks the wire protocol directly rather than pulling in a full SignalR JS client)
— which is exactly the situation where two independent hand-rolled implementations are most
likely to diverge on edge cases. This document is the contract both should match.

## Connection sequence

1. **Negotiate**: `POST {baseUrl}/auction-engine/publicAuctionEngineHub/negotiate?negotiateVersion=1`
   Headers: `apiKey`, `publicEnvironmentPath`, and `Authorization: Bearer <token>` if signed in.
   Response includes a `connectionToken` (or `connectionId`) required by the next step.
2. **Open transport** (WebSocket preferred; long-polling as a diagnostic/fallback transport —
   see `SPEC-RT-005` on connection-health reporting):
   - WebSocket URL: `wss://{host}/auction-engine/publicAuctionEngineHub?id={connectionToken}&apiKey=...&publicEnvironmentPath=...`
   - The bearer token, if any, must be sent as an `Authorization` header on the upgrade
     request — **never** as a query parameter (`SPEC-AUTH-003`).
3. **SignalR JSON-protocol handshake**: send `{"protocol":"json","version":1}` terminated by
   the record separator ``. A response containing an `error` field means the handshake
   was rejected (bad protocol/auth) — treat as a connection failure, not a connected state.
4. **Subscribe**: send `{"type":1,"target":"onHighestBidUpdate","arguments":[]}` (also
   ``-terminated). Only *after* this is sent should the client consider itself
   genuinely connected (`SPEC-RT-005`) — a socket that merely opened has not yet proven the
   hub accepted the subscription.
5. **Keep-alive**: send `{"type":6}` (a ping, no arguments) periodically (~15s) to keep the
   connection alive; ignore `type: 6` frames received from the server the same way.

## Message envelope

Every frame is one JSON object, ``-terminated, optionally batched (split on the
separator, process each independently). Relevant `type` values:

| `type` | Meaning |
|---|---|
| `1` | Invocation — either a server push (has `target`+`arguments`) or a client-to-server call. |
| `3` | Completion of an invoked call, optionally carrying an `error`. |
| `6` | Keep-alive ping. Frequent, content-free — do not log/surface as a normal event. |

A push worth acting on has `target == "onHighestBidUpdate"` (case-insensitive compare is
acceptable); anything else with `type: 1` should be logged as an unrecognized/ignored
invocation rather than silently dropped with no trace (useful for diagnosing a backend-side
change before it breaks something visibly).

## `onHighestBidUpdate` payload shape

```jsonc
{
  "amount": 53000.0,
  "isReservedPriceMet": true,          // nullable
  "currency": { "code": "CDF" },        // nullable
  "lot": {
    "id": "lot-guid",
    "endDate": "2026-08-29T18:00:00Z",
    "extendedEndDate": null,            // present once the lot has been Extended
    "runningState": { "id": 2, "name": "Running" }
  },
  "contact": { "id": "contact-guid" },   // nullable — the bidder, if an individual
  "company": { "id": "company-guid" },   // nullable — the bidder, if acting for a company
  "createdAt": "2026-08-29T17:59:58Z"    // server-assigned; the ordering key for SPEC-RT-002
}
```

Decode defensively (`SPEC-RT-006`): a payload missing an optional field should not fail the
whole update; a payload that fails to decode entirely should be logged and dropped without
affecting updates for other Lots on the same connection.

## Reconciliation contract (client-side, normative)

See `domain/06-real-time-updates.md` for full rationale. Summary of the checkable rules:

- Keyed per `lot.id`. Maintain "most recent accepted update" per Lot.
- Reject an incoming update if its `createdAt` is older than the currently-held one for that
  Lot (`SPEC-RT-002`).
- On reconnect after a drop, do not assume you missed nothing — refetch live data for every
  Lot currently on screen once reconnected, since pushes missed while disconnected are not
  replayed by this channel.
