# SAW017 — Booking Generator bulk / block generation

| | |
|--|--|
| **Status** | in-progress (HCO Test E2E **PASS**; packs next) |
| **Kind** | idempiere |
| **GitHub** | [#17](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/17) |
| **Slug** | `SAW017_booking_generator_bulk` |
| **Author (requirements)** | Jason Breen (from Amber Orr) — Draft 27/02/26 |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — ordered SQL + JARs + smoke.  
**→ [`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md)** — HCO Test pass evidence.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

Bulk or block-based generation of **Service Bookings** (`C_Order`) from **Booking Generator** records — aligned with invoice / roster / timesheet bulk generation.

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.bookinggenerator.bulk/`
- Class: `com.aberp.bookinggenerator.bulk.BulkGenerateBookings`
- Prerequisite: patched `Tickets/SAW017_booking_generator_bulk/jar/com.aberp.servicebooking.generator_*_no-opp-dep.jar` (+ deps)

## Dependencies (app)

None.

## Packs

Not yet. Next: `AbilityERP-ClientUpdate-SAW017_…` + thin `AbilityERP-ProdUpdate-SAW017_…`.
