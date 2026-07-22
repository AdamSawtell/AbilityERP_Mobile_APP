# com.aberp.servicebooking.supportdays (SAW009 + SAW031)

## SAW009 — AD/SQL

Application Dictionary: **Support Start Day** / **Support End Day** on Service Booking Line (`C_OrderLine`) use the same **14 Day Roster Period** list as Booking Generator – Service Pattern Line.

See [`Tickets/SAW009_support_day_pattern_number/DEPLOY.md`](../../Tickets/SAW009_support_day_pattern_number/DEPLOY.md).

```bash
chmod +x deploy.sh && sudo ./deploy.sh
# Cache Reset. No restart for SQL-only SAW009 path.
```

## SAW031 — Validate/Save fix (JAR)

Flamingo `MOrderLineAbERP.beforeSave` was overwriting Support days with `SimpleDateFormat("EEEE")` weekday names, which are invalid after SAW009’s List. Fix:

1. **Patched generator** — `patch/install-patched-generator.sh`
2. **Overlay ModelFactory** (optional defense) — `deploy-saw031.sh`
3. **Cleanup** — `sql/06-cleanup-weekday-text.sql`

Agent handoff: [`Tickets/SAW031_support_day_validate_fix/DEPLOY.md`](../../Tickets/SAW031_support_day_validate_fix/DEPLOY.md).

```bash
cd patch && sudo bash install-patched-generator.sh
cd .. && sudo bash deploy-saw031.sh
```

## Ordered SQL (SAW009)

1. `sql/00-preflight.sql`
2. `sql/01-add-support-day-columns.sql`
3. `sql/02-add-fields.sql`
4. `sql/03-backfill-from-pattern.sql`
5. `sql/04-sync-trigger.sql`
6. `sql/05-verify.sql`

## Ordered SQL (SAW031 add-on)

7. `sql/06-cleanup-weekday-text.sql`
8. `sql/07-verify-saw031.sql`
