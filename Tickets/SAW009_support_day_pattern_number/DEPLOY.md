# SAW009 — Deploy to another build (agent)

**Ticket / slug:** `SAW009_support_day_pattern_number`  
**Kind:** idempiere · **JAR:** No · **Status:** done

## Required host access

- SSH · `psql` · WebUI Admin · Cache Reset (no restart)

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays
# Preferred helper (includes verify):
sudo bash sql/run-install.sh
# Or manual:
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/00-preflight.sql \
  -f sql/01-add-support-day-columns.sql \
  -f sql/02-add-fields.sql \
  -f sql/03-backfill-from-pattern.sql \
  -f sql/04-sync-trigger.sql \
  -f sql/05-verify.sql
# Then Cache Reset / re-login.
```

Or thin prod pack: `Downloads\AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-*\` → `HOW-TO.txt`.

## Package

`idempiere-plugins/com.aberp.servicebooking.supportdays/`

Rollback: `sql/99-rollback.sql`

## AbilityERP Admin access

No new window/process. Fields on existing **Service Booking Line**. Admin needs Service Booking window access (pre-existing). Smoke **as Admin**.

## WebUI smoke

Service Booking → Line: Support Start/End Day numbered (`02 - Monday` / `09 - Monday`); pattern link copies days; no false day-01 without pattern.

## Packs

- Staging: `AbilityERP-ClientUpdate-SAW009_support_day_pattern_number-*`  
- Prod: `AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-*`

## External ticket text

`Tickets/SAW009_support_day_pattern_number/EXTERNAL-SUMMARY.md`
