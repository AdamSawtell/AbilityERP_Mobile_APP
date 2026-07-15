# SAW017 — Deploy to another build (agent)

**Ticket / slug:** `SAW017_booking_generator_bulk`  
**Kind:** `idempiere` · **JAR:** Yes · **Status:** Ready for other builds (HCO Test smoke PASS)  
**GitHub:** [#17](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/17)

This file is the **sole agent install runbook**. On client hosts prefer the **Downloads pack** (do not tell clients to `git pull` / run `deploy.sh` as primary).

---

## Current ship version (use this)

| Item | Value |
|------|--------|
| **Bulk JAR** | `com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar` |
| Bundle symbolic name | `com.aberp.bookinggenerator.bulk` |
| Bundle version | `7.1.0.202607160730` |
| Java class | `com.aberp.bookinggenerator.bulk.BulkGenerateBookings` |
| Process value | `AbERP_BG_BulkGenerateBookings` |
| Process UU | `17a01701-b017-4017-8017-000000000001` |
| Repo JAR copy | `Tickets/SAW017_booking_generator_bulk/jar/com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar` |
| Packs (2026-07-16) | See [Downloads packs](#downloads-packs-client-handoff) below |

Older bulk JARs in the same `jar/` folder (`…132235`, `…160715`) are historical only — **do not install them** on a new build.

### `bundles.info` line

```text
com.aberp.bookinggenerator.bulk,7.1.0.202607160730,plugins/com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar,4,true
```

Remove any prior `com.aberp.bookinggenerator.bulk,…` line before appending.

---

## What this delivers

Additive **Bulk Generate Bookings** on Booking Generator:

- New process + toolbar button + menu
- Does **not** change existing **Generate Bookings**
- Delegates each matching BG row to Generate Bookings at runtime
- Process dialog summary after run: header (period / filters / candidates), per-row OK/Skip/FAIL with **BP**, **Invoice Partner**, **Target DocType**, new SB `DocumentNo` when created, and totals

---

## Hard rules

1. Never hardcode target `AD_*_ID` — resolve by `*_UU` / name (SQL already does this).
2. Never overwrite an existing client object’s `*_UU` (HCO: never change HCO `*_UU`).
3. Prefer **patched** generator JAR (`*-no-opp-dep.jar`). Do **not** install unpatched generator unless `com.aberp.serviceopportunity.model` exists on the host.
4. JARs install **manually** via OSGi console (and/or `plugins/` + `bundles.info` per host runbook).
5. Grant **Admin** + **AbilityERP Admin** by role **name** (in `01-install-bulk-generate.sql`).

---

## Portable UUIDs (AbERP-owned)

| Object | UU | Value / name |
|--------|-----|----------------|
| Bulk process | `17a01701-b017-4017-8017-000000000001` | `AbERP_BG_BulkGenerateBookings` |
| Generate Bookings (existing) | `6482f6b8-eaa3-4e7b-a8f6-4e263d44909b` | `Generate Bookings` |
| DocAction list (required) | `285220bc-9749-4c4b-978d-4674fad038cd` | `BookingGen_DocList` |
| Booking Generator window | `de336034-bd4e-4445-b018-9c762c98d847` | `Booking Generator` |
| Bulk button column | `17a01711-b017-4017-8017-000000000011` | `AbERP_BulkGenerateBookings` |
| Bulk menu | `17a01713-b017-4017-8017-000000000013` | `Bulk Generate Bookings` |

---

## Artifacts

| Path | Use |
|------|-----|
| `idempiere-plugins/com.aberp.bookinggenerator.bulk/` | Plugin source + ordered SQL |
| `idempiere-plugins/com.aberp.bookinggenerator.bulk/sql/` | `00`…`04` AD SQL (also copied into Downloads packs) |
| `Tickets/SAW017_booking_generator_bulk/jar/` | **Ship JAR** + generator stack JARs |
| `Tickets/SAW017_booking_generator_bulk/jar/README.md` | Generator stack order + why patched |
| `Tickets/SAW017_booking_generator_bulk/hco/E2E-SMOKE-20260713.md` | HCO Test evidence (pattern only) |
| `Tickets/SAW017_booking_generator_bulk/EXTERNAL-SUMMARY.md` | Customer / external ticket paste |

---

## Prerequisites on target host

| Check | Fail closed if missing |
|-------|-------------------------|
| Window Booking Generator | UU or name |
| Table `AbERP_BookingGenerator` | Preflight |
| Process Generate Bookings AD | UU / value (WARN in preflight; runtime needs JAR too) |
| Reference `BookingGen_DocList` | Same UU as Generate Bookings DocAction list |
| Display type Yes-No (**20**) | Core |
| Role names `Admin` and/or `AbilityERP Admin` | Access grants |

If Generate Bookings **JAR** is missing: bulk AD still installs, but generation returns a clear error until the generator stack is installed.

### Generator stack (only if Generate Bookings JAR not already ACTIVE)

Copy from `Tickets/SAW017_booking_generator_bulk/jar/` — order in `jar/README.md`:

1. `com.aberp.rosteredshift.model_7.1.11.202509171959.jar`
2. `com.aberp.process.GenerateShifts_1.1.7.202508141623.jar`
3. `com.aberp.generic.utilities_7.1.4.202510091525.jar`
4. `com.aberp.servicebooking.generator_7.1.12.202602251048-no-opp-dep.jar`

---

## Install steps (agent — another build)

### A. Preflight

```sql
-- From repo or pack: sql/00-preflight.sql
```

Also confirm DocAction list exists:

```sql
SET search_path TO adempiere;
SELECT ad_reference_id, name, ad_reference_uu
FROM ad_reference
WHERE ad_reference_uu = '285220bc-9749-4c4b-978d-4674fad038cd'
   OR name = 'BookingGen_DocList';
```

### B. Copy JARs onto host

Typical paths:

- `/opt/idempiere-server/plugins/`
- optionally also `customization-jar/`
- Register in `configuration/org.eclipse.equinox.simpleconfigurator/bundles.info` using the **Current ship version** line above.

### C. OSGi console (manual)

After file copy / `bundles.info` update:

1. Restart iDempiere **or** install/start/refresh the new bundles on the console.
2. Confirm ACTIVE:
   - `com.aberp.bookinggenerator.bulk` at version **`7.1.0.202607160730`**
   - `com.aberp.servicebooking.generator` (if you installed / already had it)

### D. Ordered SQL (psql as adempiere / host DB user)

From `idempiere-plugins/com.aberp.bookinggenerator.bulk/sql/` (or pack `sql/`):

1. `00-preflight.sql`
2. `01-install-bulk-generate.sql` — process, paras, button, menu, Admin grants
3. `02-fix-docaction-list.sql` — DocAction → `BookingGen_DocList` (not `_Document Action` / 135)
4. `03-fix-yesno-display.sql` — Include* / Force Invoice Rule → Yes-No (**20**), not raw Y/N textboxes
5. `04-verify.sql` — expect process UU, 8 paras, toolbar column, role access rows

### E. Cache Reset

WebUI → **Cache Reset** (or logout/in). Required after AD SQL.

### F. Smoke (acceptance)

Use a **clean future period** (not a month that already has SBs).

1. **Admin** (or AbilityERP Admin) — Booking Generator → **Generate Bookings** (Drafted) on one STANDARD row → SB created.
2. Menu or button **Bulk Generate Bookings**:
   - Date From / Date To required
   - Optional Activity (e.g. Short Term Accommodation)
   - Include Irregular = No; Include STR = Yes only when testing STR
   - DocAction = Drafted
3. Expect process dialog summary:
   - Run header: period, activity, Include IRR/STR, Invoice Rule, DocAction, candidate count
   - Per-row `OK` / `Skip` / `FAIL` with BG key, **BP**, **Invoice Partner**, **Target DocType**; OK includes Service Booking `DocumentNo` when created in that run
   - Totals: `ok=…, skipped=…, failed=…`
   - New SBs with Invoice Rule **I** when Force = Yes
4. Confirm existing **Generate Bookings** button unchanged.
5. Confirm Include Irregular / Include STR / Force Invoice Rule show as **Yes/No** controls (not typed Y/N).

HCO Test evidence (pattern only — IDs/documentnos differ per client):  
[`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md)

---

## JAR-only upgrade (host already has SAW017 AD)

When another build already ran SQL `00`–`04` and only needs the richer process summary:

1. Copy `com.aberp.bookinggenerator.bulk_7.1.0.202607160730.jar` → `plugins/` (+ optional `customization-jar/`)
2. Update `bundles.info` to the ship version line; remove older bulk lines
3. Restart (or OSGi update/refresh)
4. Cache Reset optional for JAR-only; re-login recommended
5. Smoke: run Bulk Generate → confirm per-row BP / Invoice Partner / Target DocType in the dialog

---

## Optional: host with repo + deploy.sh

Only when the agent has SSH to a host that already has this git tree (not the preferred client path):

```bash
cd idempiere-plugins/com.aberp.bookinggenerator.bulk
chmod +x build.sh deploy.sh
./deploy.sh   # builds current VERSION, copies jar, runs 00–04 SQL, restarts
# Then Cache Reset in WebUI
```

`deploy.sh` does **not** install the Flamingo generator stack — do that separately if missing.  
Ensure `build.sh` / `deploy.sh` / `MANIFEST.MF` version is **`7.1.0.202607160730`** before building.

---

## Downloads packs (client handoff)

| Tier | Folder |
|------|--------|
| Staging / full | `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW017_booking_generator_bulk-20260716\` |
| Production thin | `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-20260716\` |

| Pack contents | Staging | Prod thin |
|---------------|---------|-----------|
| Ship bulk JAR `…160730` | `jar/` | `jar/` |
| Generator stack (+ `*-no-opp-dep`) | `jar/` | omit unless needed |
| SQL `00`–`04` | `sql/` | consolidated `01-APPLY.sql` + `99-ROLLBACK.sql` |
| How-to | `HOW-TO-UPDATE.md` | `HOW-TO.txt` |
| Pack-out | `NO-PACKOUT.txt` | n/a |

---

## Rollback (AD)

Safe reverse is limited: hide button/menu + deactivate process. Do **not** drop columns if rows were used.

```sql
SET search_path TO adempiere;
UPDATE ad_process SET isactive='N', updated=NOW()
WHERE ad_process_uu='17a01701-b017-4017-8017-000000000001';
UPDATE ad_menu SET isactive='N', updated=NOW()
WHERE ad_menu_uu='17a01713-b017-4017-8017-000000000013';
-- Stop OSGi bundle com.aberp.bookinggenerator.bulk; Cache Reset
```

---

## Known pitfalls (carry forward)

| Issue | Fix |
|-------|-----|
| DocAction empty / mandatory fail | Use `BookingGen_DocList`, not `_Document Action` (135 has no `DR`) |
| Y/N textboxes instead of Yes/No | `ad_reference_id=20` via `03-fix-yesno-display.sql` |
| Bundle won’t resolve (generator) | Use `*-no-opp-dep.jar`; never Require `serviceopportunity.model` without the JAR |
| `ad_pinstance` queries hang | Filter by `ad_process_id` + `created` window |
| Generate Bookings OK but no new SB | Pattern/period already covered — normal for underlying generator |
| Temporary smoke defaults left on DateFrom/Activity | Keep production defaults empty / IncludeSTR=`N` |
| Wrong bulk JAR version | Must be **`7.1.0.202607160730`** for summary with BP / Invoice Partner / Target DocType |

---

## HCO-specific

See [`NOTES.md`](NOTES.md) § **HCO Future Deployments variables** and [`.cursor/rules/hco-deployment.mdc`](../../.cursor/rules/hco-deployment.mdc). Append [`Tickets/HCO_Deployment/LEARNINGS.md`](../HCO_Deployment/LEARNINGS.md) after each HCO install.

Current preferred Test host for this ticket: `13.210.248.141` (key `c:\Users\sawte\Documents\SSH Keys\HCObusiness.pem`).
