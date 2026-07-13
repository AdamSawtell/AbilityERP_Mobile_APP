# SAW015 — Deploy to another build (agent)

**Ticket / slug:** `SAW015_skip_dates_copy_from`  
**Kind:** idempiere · **JAR:** Yes · **Status:** HCO Test green (2026-07-13); ready for other builds / UAT

Point agents here (not chat history). Repo home: `Tickets/SAW015_skip_dates_copy_from/`.

## Required host access

- SSH to iDempiere host  
- `psql` on DB `idempiere` (schema `adempiere`)  
- WebUI Admin login  
- Ability to **stop then start** iDempiere and check OSGi bundle state  
- Do **not** wipe `configuration/org.eclipse.osgi`

## Prerequisites (fail closed)

Target must already have:

| Object | Resolve by |
|--------|------------|
| Window **Skip Dates** | UU `b3037901-e883-42f2-8e6d-c8e759ca91cd` **or** name `Skip Dates` |
| Table **AbERP_Skip_Dates** | UU `88130ae9-2aac-4c86-9c98-f94b272af212` **or** `tablename` |
| Table **AbERP_Dates** | UU `bac8f234-c300-45f5-b8bb-5f7c7a0a2152` **or** `tablename` |
| Header tab **Skip Dates** | UU `4224ab0d-fa68-44ac-9371-eb5fd100c3b3` **or** window+tab name |

Preflight script raises if missing. Never hardcode `AD_*_ID` across clients. Never change existing client `*_UU` values.

## Agent one-liner (preferred)

```bash
cd idempiere-plugins/com.aberp.skipdates.copyfrom
chmod +x build.sh deploy.sh
./deploy.sh
# Builds JAR (if needed), copies to plugins/ + customization-jar/, updates bundles.info,
# runs 00-preflight + 01-install (+ 02 button style), stop then start iDempiere.
# Then: Cache Reset or logout/in on WebUI. Confirm bundle ACTIVE.
```

## Manual install (no deploy.sh)

1. Build JAR on host (or copy from pack):
   ```bash
   cd idempiere-plugins/com.aberp.skipdates.copyfrom && bash build.sh
   # → build/dist/com.aberp.skipdates.copyfrom_7.1.0.202607131830.jar
   ```
2. Install JAR:
   - Copy to `$IDEMPIERE_HOME/plugins/` and `$IDEMPIERE_HOME/customization-jar/`
   - In `configuration/org.eclipse.equinox.simpleconfigurator/bundles.info`, replace any prior line for this symbolic name with:
     ```
     com.aberp.skipdates.copyfrom,7.1.0.202607131830,plugins/com.aberp.skipdates.copyfrom_7.1.0.202607131830.jar,4,true
     ```
3. Apply SQL (ordered):
   ```bash
   cd idempiere-plugins/com.aberp.skipdates.copyfrom/sql
   psql -d idempiere -v ON_ERROR_STOP=1 \
     -f 00-preflight.sql \
     -f 01-install-copy-dates-from.sql \
     -f 02-button-window-style.sql \
     -f 04-verify.sql
   ```
4. **Stop then start** iDempiere (do not rely on `systemctl restart` alone — it can no-op when Java is already down).
5. Confirm OSGi: bundle `com.aberp.skipdates.copyfrom` is **ACTIVE**.
6. WebUI **Cache Reset** or logout/in.

## Package / bundle

| | |
|--|--|
| Plugin path | `idempiere-plugins/com.aberp.skipdates.copyfrom/` |
| Process class | `com.aberp.skipdates.copyfrom.CopyDatesFrom` |
| Bundle symbolic name | `com.aberp.skipdates.copyfrom` |
| Version | `7.1.0.202607131830` |
| Primary AD | `sql/01-install-copy-dates-from.sql` (idempotent; UU/name lookups) |
| Optional | `sql/02-button-window-style.sql` (ensure `IsToolbarButton = B`) |
| Verify | `sql/04-verify.sql` |
| Rollback AD | `sql/99-rollback.sql` (remove JAR from plugins/`bundles.info` separately) |

### AbERP-owned fixed UUs (portable)

| Object | UU |
|--------|-----|
| Process | `15a01501-c0d4-4f01-8e15-000000000001` |
| Element | `15a01502-c0d4-4f01-8e15-000000000002` |
| Column | `15a01503-c0d4-4f01-8e15-000000000003` |
| Field | `15a01504-c0d4-4f01-8e15-000000000004` |
| Process para | `15a01505-c0d4-4f01-8e15-000000000005` |
| Val rule | `15a01506-c0d4-4f01-8e15-000000000006` |

### SQL scripts (source of truth under plugin)

| Script | Purpose |
|--------|---------|
| `00-preflight.sql` | Fail if Skip Dates window/tables/tab missing |
| `01-install-copy-dates-from.sql` | Process, para, element, column, field, Admin access |
| `02-button-window-style.sql` | Window button style `B` |
| `04-verify.sql` | Confirm process/column/field/access |
| `99-rollback.sql` | Remove AD objects (keeps business date data) |

Ticket copies of the same SQL also live under `Tickets/SAW015_skip_dates_copy_from/sql/` (prefer plugin path for deploy).

## AbilityERP Admin access

`01-install-copy-dates-from.sql` grants `AD_Process_Access` by role **name** to:

- **AbilityERP Admin**
- **Admin** (HCO / operational)
- System Administrator (`AD_Role_ID = 0`)

Smoke **as Admin**. If button missing after install: logout/in or Role Access Update.

## What the process does

1. Runs from saved **Skip Dates** header (`AbERP_Skip_Dates`).
2. Parameter: **Copy From Skip Dates** (Search; excludes current record).
3. Copies all `AbERP_Dates` lines (StartDate, EndDate, Description, IsActive) to the current header with **new** IDs/UUs.
4. Source rows are not updated.
5. Help + result message warn user to review/update years and individual dates; result includes copy count.

## WebUI smoke

1. Cache Reset / re-login as **Admin**.
2. Open **Skip Dates** → create and save a new header (or open one with no dates).
3. Click **Copy Dates From** → select a source Skip Dates that has date lines.
4. Confirm the date-review warning in the process dialog.
5. Confirm success: “Copied N date record(s)…” and Dates tab shows N rows.
6. Open source Skip Dates → Dates count unchanged.
7. Edit or delete a copied line on the target.

## Packs (Downloads)

- Staging: `AbilityERP-ClientUpdate-SAW015_skip_dates_copy_from-20260713` (`HOW-TO-UPDATE.md` + sql/ + jar/)
- Thin prod: `AbilityERP-ProdUpdate-SAW015_skip_dates_copy_from-20260713` (`HOW-TO.txt` + `01-APPLY.sql` + JAR + `99-ROLLBACK.sql`)

Client hosts: install JAR via OSGi / `plugins` + `bundles.info` per pack HOW-TO — do not require git pull as the primary path.

## Portability / known HCO learnings

| Issue | Fix already in repo |
|-------|---------------------|
| UU columns are `varchar` | SQL uses `TEXT` UU variables |
| `nextid` is OUT-only on some hosts | Use `nextidfunc` |
| `systemctl restart` can no-op | `deploy.sh` stops then starts |

## External ticket text

`Tickets/SAW015_skip_dates_copy_from/EXTERNAL-SUMMARY.md`

## HCO notes

See `NOTES.md` § HCO Future Deployments variables and `Tickets/HCO_Deployment/LEARNINGS.md` (2026-07-13 SAW015).
