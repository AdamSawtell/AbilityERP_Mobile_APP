# SAW010 — Deploy to another build (agent)

**Ticket / slug:** `SAW010_timesheet_approval_info_columns`  
**GitHub:** [#10](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/10)  
**Kind:** idempiere · **This pack JAR:** No · **Status:** done (Info columns)

Point agents here (or at issue #10). Do **not** invent new InfoColumn UUs on a client that already has the owned Break UUs below.

## Required host access

| Need | Why |
|------|-----|
| SSH to iDempiere host | Copy/run SQL |
| `psql` on DB `idempiere`, schema `adempiere` | Apply / verify |
| WebUI AbilityERP Admin (or **Admin** on HCO) | Cache Reset + smoke |
| Optional: OSGi console | Only if restoring timesheetapproval **process** JAR (separate from this pack) |

## Agent one-liner (repo on host)

```bash
cd /opt/ability-erp-pwa/idempiere-plugins/com.aberp.timesheet.approvalinfo   # or repo path
chmod +x deploy.sh
sudo ./deploy.sh
# Then WebUI Cache Reset (or logout/in). No iDempiere restart for this SQL pack.
```

**Prefer Downloads pack** when shipping to a client (no git pull required):

- Thin prod: `Downloads\AbilityERP-ProdUpdate-SAW010_timesheet_approval_info_columns-20260712\`  
  Order: `00-PREFLIGHT.sql` → `01-APPLY.sql` → Cache Reset  
  Rollback: `99-ROLLBACK.sql`
- Full staging: `Downloads\AbilityERP-ClientUpdate-SAW010_timesheet_approval_info_columns-20260712\`  
  (`HOW-TO-UPDATE.md` + `sql/00`…`03` + `99-rollback`)

## Package / source of truth

`idempiere-plugins/com.aberp.timesheet.approvalinfo/`

| File | Purpose |
|------|---------|
| `sql/00-preflight-uuids.sql` | Fail closed if Info Window / break physical cols / process bind missing |
| `sql/01-update-infocolumns.sql` | Hide grid cols + upsert Break Start/End |
| `sql/02-verify.sql` | Assert display flags / seqnos |
| `sql/03-functional-check.sql` | Sample query shape |
| `sql/04-seed-test-rows.sql` | **Staging AbilityERP seed only** — hardcodes client/org; **never on foreign clients** |
| `sql/99-rollback.sql` | Restore prior display; delete Break InfoColumns |
| `deploy.sh` | Runs 00→01→02→03 |

## Target objects (UUID — portable)

| Object | UU | Notes |
|--------|-----|--------|
| Info Window Timesheet Approval | `40d6a2d7-3bbc-431e-940c-ce75829a68e4` | Must exist (preflight) |
| Process AbERP Set Timesheet Approved Status | `3a3c2c41-995c-41ba-9fde-caeaacee1d75` | Must stay bound to Timesheet ID InfoColumn |
| Hide: Shift Cost | `39fb0ffb-58e5-46e7-8966-48b2fb223b86` | `isdisplayed=N` |
| Hide: Name | `6f1c18f1-43b5-4cab-8f13-8d5960c602cd` | `isdisplayed=N` |
| Hide: Employee (IsEmployee) | `750b7e9f-1299-49c6-8477-616de3c4b0de` | grid N; keep criteria |
| Hide: Activity | `890d8791-326b-4092-beb5-9046587d7556` | grid N; keep criteria |
| Hide: Business Partner | `61e09e5f-222b-4bb6-bb29-ae8fb785f4e9` | grid N; keep criteria |
| Keep visible: Employee (User)/Agency Staff | `a7d9bd78-d602-4c53-a2ee-11a92f9600b1` | |
| Keep hidden key: Timesheet ID | `8b6c8946-96eb-4b8f-b45c-c5f7ba41bfdd` | InfoProcess bind — **do not remove** |
| Break Start (owned) | `c4e8a1b2-5d6f-4a7c-9e01-2b3d4f5a6c70` | `t.AbERP_Break_Start`, seq 72, Date+Time |
| Break End (owned) | `d5f9b2c3-6e70-4b8d-a012-3c4e5f6a7b81` | `t.AbERP_Break_End`, seq 74, Date+Time |

**Physical columns (must already exist):** `aberp_timesheetandexpenses.aberp_break_start`, `aberp_break_end`. This pack does **not** create them.

**Never hardcode** numeric `AD_InfoWindow_ID` / `AD_InfoColumn_ID` across clients — resolve by `*_UU` only.

## What the pack changes

1. Hide from **result grid**: Shift Cost, Name, Employee (Y/N), Activity, Business Partner.  
2. Keep as **search filters** where they were criteria (Activity, Employee, Business Partner, dates, etc.).  
3. Retain **Employee (User) / Agency Staff** as the only staff display column.  
4. Add **Break Start** / **Break End** immediately after **Shift Type**.

## AbilityERP Admin access

No new window/menu. Updates existing Timesheet Approval Info. Smoke as AbilityERP Admin (HCO: SuperUser → **Admin**).  
Approve button needs existing process access **plus** process JAR (below).

## Restart / cache

- **No** OSGi restart for this SQL pack  
- **Yes** Cache Reset or logout/in before WebUI smoke

## WebUI smoke (required)

1. Open **Timesheet Approval**.  
2. ReQuery — expect grid: Employee (User)/Agency Staff, Start, End, Shift Type, **Break Start**, **Break End**, Contract Location, Description, Status, Supervisor.  
3. Confirm **not** in grid: Shift Cost, Name, Employee (Y/N), Activity, Business Partner.  
4. Confirm filters still present for Activity / Employee / Business Partner / dates.  
5. Select a row → **AbERP Set Timesheet Approved Status** dialog opens (Timesheet ID bind OK).

## Separate host dependency (not in this pack)

| | |
|--|--|
| Class | `com.aberp.timesheetapproval.processes.setstatus` |
| Symptom if missing | `ClassNotFoundException` / Failed to create process instance |
| Action on client | Confirm timesheetapproval process plugin JAR installed/started; retest approve **execute** |
| SAW010 scope | AD/SQL columns only — packs ship `NO-JAR.txt` |

## HCO / other clients

- See `NOTES.md` → **HCO Future Deployments variables** (UUs matched; local IDs differ).  
- **Never change** existing HCO `*_UU` values.  
- Learnings: `Tickets/HCO_Deployment/LEARNINGS.md` (append after each HCO install).

## Portability risks

- Preflight **raises** if Info Window UU missing or FROM alias `t` wrong — do not patch by ID.  
- Preflight requires break physical columns and process InfoProcess bind.  
- `04-seed-test-rows.sql` is AbilityERP staging-only.  
- Process JAR absence does not block column install; only blocks approve execute.

## Rollback

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/99-rollback.sql
# Cache Reset
```

## External ticket text

`Tickets/SAW010_timesheet_approval_info_columns/EXTERNAL-SUMMARY.md`
