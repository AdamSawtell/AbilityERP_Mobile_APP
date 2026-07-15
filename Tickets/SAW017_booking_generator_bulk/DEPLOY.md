# SAW017 — Deploy to another build (agent)

**Ticket / slug:** `SAW017_booking_generator_bulk`  
**Kind:** `idempiere` · **JAR:** Yes · **Status:** HCO Test E2E **PASS** (2026-07-13); ready for other builds / packs  
**GitHub:** [#17](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/17)

This file is the **sole agent install runbook**. Prefer the **Downloads pack** on client hosts (do not tell clients to `git pull` / run `deploy.sh` as primary).

---

## What this delivers

Additive **Bulk Generate Bookings** on Booking Generator:

- New process `AbERP_BG_BulkGenerateBookings` (UU below)
- New toolbar button + menu entry
- Does **not** change existing **Generate Bookings**
- At runtime delegates each matching BG row to Generate Bookings (UU below)

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

## Artifacts in this repo

| Path | Use |
|------|-----|
| `idempiere-plugins/com.aberp.bookinggenerator.bulk/` | Plugin source + ordered SQL |
| `idempiere-plugins/com.aberp.bookinggenerator.bulk/sql/` | `00`…`04` AD SQL |
| `Tickets/SAW017_booking_generator_bulk/jar/` | Built bulk JAR + generator stack JARs |
| `Tickets/SAW017_booking_generator_bulk/jar/README.md` | Generator stack order + why patched |
| `Tickets/SAW017_booking_generator_bulk/hco/E2E-SMOKE-20260713.md` | HCO Test evidence |

**Bulk JAR filename:** `com.aberp.bookinggenerator.bulk_7.1.0.202607132235.jar`  
**Class:** `com.aberp.bookinggenerator.bulk.BulkGenerateBookings`

---

## Prerequisites on target host

| Check | Fail closed if missing |
|-------|-------------------------|
| Window Booking Generator | UU or name |
| Table `AbERP_BookingGenerator` | Preflight |
| Process Generate Bookings AD | UU / value (WARN in preflight; runtime needs JAR too) |
| Reference `BookingGen_DocList` | Same UU as Generate Bookings DocAction list |
| Reference Yes-No (20) | Core |
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
-- From repo: idempiere-plugins/com.aberp.bookinggenerator.bulk/sql/00-preflight.sql
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
- Register in `configuration/org.eclipse.equinox.simpleconfigurator/bundles.info`  
  Example line:  
  `com.aberp.bookinggenerator.bulk,7.1.0.202607132235,plugins/com.aberp.bookinggenerator.bulk_7.1.0.202607132235.jar,4,true`

### C. OSGi console (manual)

After file copy / `bundles.info` update:

1. Restart iDempiere **or** install/start/refresh the new bundles on the console.
2. Confirm ACTIVE:  
   - `com.aberp.bookinggenerator.bulk`  
   - `com.aberp.servicebooking.generator` (if you installed / already had it)

### D. Ordered SQL (psql as adempiere / host DB user)

From `idempiere-plugins/com.aberp.bookinggenerator.bulk/sql/`:

1. `00-preflight.sql`
2. `01-install-bulk-generate.sql` — process, paras, button, menu, Admin grants
3. `02-fix-docaction-list.sql` — DocAction → `BookingGen_DocList` (not `_Document Action` / 135)
4. `03-fix-yesno-display.sql` — Include* / Force Invoice Rule → Yes-No (**20**), not raw Y/N textboxes
5. `04-verify.sql` — expect process UU, 8 paras, toolbar column, role access rows

### E. Cache Reset

WebUI → **Cache Reset** (or logout/in). Required after AD SQL.

### F. Smoke (acceptance)

Use a **clean future period** (not a month that already has SBs).

1. **Admin** (or AbilityERP Admin) — Booking Generator search a STANDARD row → **Generate Bookings** (Drafted) → SB created, Invoice Rule Immediate if forced on BG path.
2. Menu or button **Bulk Generate Bookings**:
   - Date From / Date To required  
   - Optional Activity (e.g. Short Term Accommodation)  
   - Include Irregular = No; Include STR = Yes only when testing STR  
   - DocAction = Drafted  
3. Expect process dialog summary covering:
   - Run header: period, activity, Include IRR/STR, Invoice Rule, DocAction, candidate count
   - Per-row `OK` / `Skip` / `FAIL` lines (OK includes Service Booking `DocumentNo` when created in that run)
   - Totals: `ok=…, skipped=…, failed=…`
   - New SBs with Invoice Rule **I** when Force = Yes
4. Confirm existing **Generate Bookings** button unchanged.
5. Confirm Include Irregular / Include STR / Force Invoice Rule show as **Yes/No** controls (not typed Y/N).

HCO Test evidence (pattern only — IDs/documentnos differ per client):  
[`hco/E2E-SMOKE-20260713.md`](hco/E2E-SMOKE-20260713.md)

---

## Optional: host with repo + deploy.sh

Only when the agent has SSH to a host that already has this git tree (not the preferred client path):

```bash
cd idempiere-plugins/com.aberp.bookinggenerator.bulk
chmod +x build.sh deploy.sh
./deploy.sh   # builds, copies jar, runs 00–04 SQL, restarts
# Then Cache Reset in WebUI
```

`deploy.sh` does **not** install the Flamingo generator stack — do that separately if missing.

---

## Downloads packs (client handoff)

| Tier | Folder pattern |
|------|----------------|
| Staging / full | `Downloads\AbilityERP-ClientUpdate-SAW017_booking_generator_bulk-YYYYMMDD\` |
| Production thin | `Downloads\AbilityERP-ProdUpdate-SAW017_booking_generator_bulk-YYYYMMDD\` |

Pack layout: `HOW-TO-UPDATE.md` (or `HOW-TO.txt`), `sql/`, `jar/`, `packout/` or `NO-PACKOUT.txt`, `docs/`.

---

## Rollback (AD)

Safe reverse is limited: hide button/menu + deactivate process. Do **not** drop columns if rows were used. Prefer document-only deactivate:

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

---

## HCO-specific

See [`NOTES.md`](NOTES.md) § **HCO Future Deployments variables** and [`.cursor/rules/hco-deployment.mdc`](../../.cursor/rules/hco-deployment.mdc). Append [`Tickets/HCO_Deployment/LEARNINGS.md`](../HCO_Deployment/LEARNINGS.md) after each HCO install.
