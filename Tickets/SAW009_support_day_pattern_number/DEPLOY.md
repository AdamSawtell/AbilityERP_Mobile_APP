# SAW009 — Deploy to another build

**Ticket:** SAW009_support_day_pattern_number · **Kind:** idempiere · **JAR:** No

## Agent one-liner

bash
cd idempiere-plugins/com.aberp.servicebooking.supportdays
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/00-preflight.sql \
  -f sql/01-add-support-day-columns.sql \
  -f sql/02-add-fields.sql \
  -f sql/03-backfill-from-pattern.sql \
  -f sql/04-sync-trigger.sql
# optional: -f sql/05-verify.sql
# Or: -f sql/install-all.sql
# Then Cache Reset + re-login. No iDempiere restart.


**Thin prod pack (preferred when present):**

Downloads\AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-*\ → follow HOW-TO.txt (01-APPLY.sql / 99-ROLLBACK.sql).

## Package

idempiere-plugins/com.aberp.servicebooking.supportdays/

## Restart / cache

- **No** restart  
- **Yes** Cache Reset + re-login

## WebUI smoke

1. **Service Booking → Service Booking Line**: Support Start/End Day show pattern numbers (e.g. 02 - Monday / 09 - Monday).  
2. Linking a pattern copies days; Start and End independent.  
3. No pattern link → leave historical values / null (no false day-01 guess).

## Blockers / notes

- Generate Bookings JAR may be absent; sync uses DB trigger when pattern ID is set.  
- Optional full WebUI smoke may still be open on checklist.


## AbilityERP Admin access (mandatory)

Install SQL / deploy must grant **AbilityERP Admin** access to every new or newly exposed **window**, **process**, **Info Window**, and **form** (and process access for toolbar buttons). See docs/DEV-REQUIREMENTS.md. After grant: Role Access Update or logout/in. Smoke as Admin.

## Packs

- Staging: AbilityERP-ClientUpdate-SAW009_support_day_pattern_number-*  
- Prod: AbilityERP-ProdUpdate-SAW009_support_day_pattern_number-*
