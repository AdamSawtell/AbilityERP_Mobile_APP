# SAW017 — Booking Generator bulk / block generation

| | |
|--|--|
| **Status** | Ready for other-build deploy (HCO Test PASS; ship JAR `160730`) |
| **Kind** | idempiere |
| **GitHub** | [#17](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/17) |
| **Slug** | `SAW017_booking_generator_bulk` |
| **Ship JAR** | `com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar` |

## Agent deploy (mandatory)

**→ [`DEPLOY.md`](DEPLOY.md)** — sole install runbook: prerequisites, UUIDs, **current JAR**, SQL order, OSGi, Cache Reset, smoke, JAR-only upgrade, pitfalls.

**→ Packs (2026-07-16) — prefer these for client hosts:**

- `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW017_booking_generator_bulk-20260716\`
- `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-20260716\`

Repo mirror of the ship JAR: [`jar/com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar`](jar/com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar) · details [`jar/README.md`](jar/README.md)

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.bookinggenerator.bulk/` |
| Class | `com.aberp.bookinggenerator.bulk.BulkGenerateBookings` |
| SQL | `…/sql/00` … `04` |
| Ship JAR | `Tickets/SAW017_booking_generator_bulk/jar/…160730.jar` |
| HCO smoke | [`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md) |
| HCO variables | [`NOTES.md`](NOTES.md) § HCO Future Deployments |

## Dependencies (app)

None.
