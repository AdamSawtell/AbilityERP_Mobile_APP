# com.aberp.servicebooking.supportdays (SAW009)

SQL-only Application Dictionary change: add **Support Start Day** / **Support End Day** on Service Booking Line (`C_OrderLine`), displayed with the same numbered format as Booking Generator – Service Pattern Line (`14 Day Roster Period`).

## Install order

1. `sql/00-preflight.sql`
2. `sql/01-add-support-day-columns.sql`
3. `sql/02-add-fields.sql`
4. `sql/03-backfill-from-pattern.sql`
5. `sql/04-sync-trigger.sql`

Or: `sql/install-all.sql`

Then **Cache Reset** and re-login.

## No JAR

AD + DB columns + backfill + sync trigger only.
