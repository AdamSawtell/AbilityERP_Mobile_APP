# com.aberp.servicebooking.supportdays (SAW009)

SQL-only Application Dictionary change: **Support Start Day** / **Support End Day** on Service Booking Line (`C_OrderLine`) use the same **14 Day Roster Period** list as Booking Generator – Service Pattern Line.

## Agent install (other builds)

**Read first:** [`Tickets/SAW009_support_day_pattern_number/DEPLOY.md`](../../Tickets/SAW009_support_day_pattern_number/DEPLOY.md)

```bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays
chmod +x deploy.sh && sudo ./deploy.sh
# Cache Reset / logout-in. No restart. No JAR.
```

## Ordered SQL

1. `sql/00-preflight.sql`
2. `sql/01-add-support-day-columns.sql`
3. `sql/02-add-fields.sql`
4. `sql/03-backfill-from-pattern.sql`
5. `sql/04-sync-trigger.sql`
6. `sql/05-verify.sql` (via `deploy.sh`)

Rollback: `sql/99-rollback.sql`

## Portability

If columns/fields already exist on the client, SQL updates List reference / display only and **does not overwrite** existing `AD_Column` / `AD_Field` UUs (HCO-safe).
