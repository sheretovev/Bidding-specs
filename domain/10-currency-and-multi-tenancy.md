# Currency & Multi-Tenancy

## SPEC-I18N-001 — Every client call is scoped to a Public Environment

The backend serves multiple storefronts/tenants ("Public Environments," e.g.
`auction_website`) off one platform. A client identifies which one it's speaking for on every
call via an API key plus an environment path, sent as a header or query parameter alongside
any user-level bearer token. This scoping is independent of user identity: an anonymous
browsing session and a signed-in bidder's session both carry it. A new platform must be
configured with its own Public Environment identity before it can call any endpoint — there
is no environment-less mode.

## SPEC-I18N-002 — Every monetary amount is currency-qualified; never assume a default

Lots, Bids, and Max Bids each carry their own currency (a code, e.g. `USD`/`AZN`/`CDF`) —
this is not a single global currency for the whole platform. A client must always render an
amount together with its accompanying currency code from the same record, and must not
fall back to a hardcoded default currency when one is legitimately present on the data,
reserving a fallback (clearly, e.g. showing no currency suffix rather than a wrong one) only
for the genuine absence of data. Comparing or summing amounts across records (e.g. a
dashboard total) is only valid when all contributing records share a currency; when they
don't, aggregate a currency-labeled breakdown instead of a single misleading total figure.

## SPEC-I18N-003 — Locale-appropriate number formatting, not string concatenation

Amounts should be formatted using the platform's locale-aware currency/number formatting
(e.g. grouping separators, currency symbol placement) rather than naive string
concatenation of a raw number and a currency code. Both are acceptable in principle; a raw
`amount + " " + code` fallback is fine when a proper currency formatter isn't available for
an unrecognized code, but should not be the default path for known currencies.
