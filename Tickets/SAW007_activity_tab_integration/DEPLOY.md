# SAW007 — Deploy to another build (agent)

**Ticket / slug:** `SAW007_activity_tab_integration`  
**Kind:** idempiere · **JAR:** marker (`com.aberp.contactactivity.tabs`) · **Status:** done

## Required host access

- SSH · `psql` · WebUI Admin · restart if installing JAR  
- Prerequisite: Contact Activity / Enquiry Activity patterns exist on the client

## Agent one-liner (OTHER BUILDS — default)

```bash
cd idempiere-plugins/com.aberp.contactactivity.tabs
chmod +x build.sh deploy.sh
./deploy.sh
# Default = portable: sql/01 + register-contactactivity-tabs.sql + fix-activity-user-contact.sql
# then restart + logout/in
```

**Do not** set `ABERP_ACTIVITY_SEED_SQL=1` on another client — that path hardcodes window IDs (`1000193` / `1000077` / `1000118`).

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.contactactivity.tabs/` |
| Symbolic name | `com.aberp.contactactivity.tabs` |
| Version | `7.1.0.202607092300` |

## Ordered SQL (portable — what `deploy.sh` runs by default)

1. `sql/01-add-link-columns.sql`  
2. `register-contactactivity-tabs.sql` (repo package root)  
3. `fix-activity-user-contact.sql`  
4. `sql/04-ensure-activity-types.sql` — Email / Meeting / Phone call / Case Note / Task on each window  

Optional: `hide-activity-user-contact.sql`

**HCO delta (tabs already installed):** run only `sql/04-ensure-activity-types.sql`, then logout/in.

**Seed-only (reference tenant):** `sql/02-add-activity-tabs.sql` + `sql/03-update-activity-type-windows.sql` via `ABERP_ACTIVITY_SEED_SQL=1`.

## AbilityERP Admin access

Tabs are added to **existing** windows — Admin needs access to those parent windows (Booking Generator / Service Booking / Service Agreement). No new process. If tabs missing for Admin after logout/in, grant window access by role **name**. Smoke **as Admin**.

## WebUI smoke

Each target window → **Activity** → New → Activity Type shows **Email, Meeting, Phone call, Case Note, Task**; save; confirm user/contact behaviour after fix script.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW007_activity_tab_integration-20260712\`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW007_activity_tab_integration-20260712\`  
  - Fresh: `01-APPLY.sql`  
  - HCO already installed: `02-DELTA-activity-types-only.sql`

## External ticket text

`Tickets/SAW007_activity_tab_integration/EXTERNAL-SUMMARY.md`
