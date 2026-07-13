# SAW017 — Booking Generator bulk / block generation

| | |
|--|--|
| **Status** | in-progress (additive bulk plugin scaffolded; Flamingo generator deps still needed for live generate) |
| **Kind** | idempiere |
| **GitHub** | [#17](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/17) |
| **Slug** | `SAW017_booking_generator_bulk` |
| **Author (requirements)** | Jason Breen (from Amber Orr) — Draft 27/02/26 |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** — TBD after host discovery of existing Generate* JARs and design sign-off. Expect new process JAR + AD SQL + Admin grants.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** — draft scope summary for customer ticket (update when delivered).

## Goal

Bulk or block-based generation of **Service Bookings** (`C_Order`) from **Booking Generator** (`AbERP_BookingGenerator`) records — aligned with invoice / roster / timesheet bulk generation — so ops do not manually run Generate Bookings ~206 times per month.

## Source of truth (planned)

- Plugin: `idempiere-plugins/com.aberp.bookinggenerator.bulk/`
- Class: `com.aberp.bookinggenerator.bulk.BulkGenerateBookings`
- Prerequisite JAR (vendor): `Tickets/SAW017_booking_generator_bulk/jar/com.aberp.servicebooking.generator_7.1.12.*.jar` (+ OSGi deps)

## Dependencies (app)

None.

## Out of scope (document only)

- Invoice Partner resetting to client name on BG copy
- Mandatory Description month/year automation (may remain admin step)

## Packs

Not yet. After staging green: `AbilityERP-ClientUpdate-SAW017_…` + thin `AbilityERP-ProdUpdate-SAW017_…`.

## Related

- [`NOTES.md`](NOTES.md) — generator review + recommended approach
- SAW009 — Support days after Generate Bookings stamps pattern FK
- SAW015 — Skip Dates / exclusion calendars; in-repo `SvrProcess` pattern
- SAW010 — Timesheet Approval Info multi-select process pattern
