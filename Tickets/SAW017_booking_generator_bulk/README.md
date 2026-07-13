# SAW017 — Booking Generator bulk / block generation

| | |
|--|--|
| **Status** | HCO Test E2E **PASS**; packs ready for other builds |
| **Kind** | idempiere |
| **GitHub** | [#17](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/17) |
| **Slug** | `SAW017_booking_generator_bulk` |

## Agent deploy (mandatory)

**→ [`DEPLOY.md`](DEPLOY.md)** — full install: JARs, SQL order, OSGi, Cache Reset, smoke, pitfalls.

**→ Packs (2026-07-14):**

- `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW017_booking_generator_bulk-20260714\`
- `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-20260714\`

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.bookinggenerator.bulk/` |
| Class | `com.aberp.bookinggenerator.bulk.BulkGenerateBookings` |
| SQL | `…/sql/00` … `04` |
| JARs | `Tickets/SAW017_booking_generator_bulk/jar/` |
| HCO smoke | [`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md) |

## Dependencies (app)

None.
