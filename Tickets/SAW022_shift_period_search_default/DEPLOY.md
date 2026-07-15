# SAW022 — Deploy to another build (agent)

**Ticket / slug:** `SAW022_shift_period_search_default`  
**Kind:** idempiere · **JAR:** No

## Required host access

- SSH + `psql` on `idempiere` / schema `adempiere`
- WebUI admin (Cache Reset / logout-in)

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.rosteredshift.perioddefault
# as postgres or with PGPASSWORD=adempiere:
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/00-preflight.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/01-set-period-default.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/02-verify.sql
# Cache Reset or logout/in. No restart.
```

Or: `chmod +x deploy.sh && ./deploy.sh` (when DB env vars are set for adempiere user).

## Target objects (by UU — do not hardcode IDs)

| Object | UU |
|--------|-----|
| Window Shift (Rostered) | `7c269a7e-65dd-4287-8d53-f7f3ca09ee00` |
| Tab Shift (Rostered) | `29867696-9561-462f-89f9-f92c26c8ea02` |
| Field Roster Period | `9099644b-d5cf-4b32-9921-1776cac6bd66` |
| UserQuery * Current Pay Period | `6b2c9e11-4d8a-4f01-9b2e-a022shift001` |

## Notes

Field DefaultValue alone does **not** populate Lookup for virtual `AbERP_PR_Period_ID` on this build. The working default is the shared **UserQuery** with dynamic `@SQL=EXISTS` against `AbERP_PR_Period`.

## AbilityERP Admin access

No new window/process/Info Window — existing Shift (Rostered) access only. No grant SQL.

## Restart / cache

- **No** OSGi/restart · **Yes** Cache Reset or logout/in

## WebUI smoke

1. Login Admin (HCO: SuperUser → Admin).
2. Open **Shift (Rostered)** (opens in Search).
3. Confirm Saved Query = **\* Current Pay Period**.
4. OK — results limited to that period (pager ~thousands, not ~100k).
5. Switch to **\* New Query \*\*** or a location saved query — works as before.

## Portability risks

- Field UU must exist (preflight fails closed).
- Requires `AbERP_PR_Period` rows and working `@#Date@` / `@#AD_Client_ID@` context (standard WebUI).
- Find still evaluates virtual `fn_get_roster_period(StartDate)` — acceptable for period-sized result sets.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW022_shift_period_search_default-<YYYYMMDD>\`
- Thin prod: `Downloads\AbilityERP-ProdUpdate-SAW022_shift_period_search_default-<YYYYMMDD>\`

## External ticket text

`Tickets/SAW022_shift_period_search_default/EXTERNAL-SUMMARY.md`

## HCO Future Deployments variables

See `NOTES.md`.
