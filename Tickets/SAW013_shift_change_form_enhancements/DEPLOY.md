# SAW013 — Deploy to another build (agent)

**Ticket / slug:** `SAW013_shift_change_form_enhancements`  
**Kind:** `idempiere` · **JAR:** No · **Restart:** No  
**Status:** Staging green on HCO Test · packs ready  
**GitHub:** [#13](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/13)  
**Home:** `Tickets/SAW013_shift_change_form_enhancements/`

Point agents here (not chat history). Source of truth: `idempiere-plugins/com.aberp.shiftchange.form/`.

## Required host access

- SSH to iDempiere host (or bastion)
- `psql` on `idempiere` / `adempiere` (rights to change AD + create triggers)
- WebUI Admin (or AbilityERP Admin)
- Cache Reset (or logout/in) — **required** after SQL

## Prerequisites (fail closed)

Target build must already have:

| Object | Resolve by | Notes |
|--------|------------|--------|
| Window **HCO Forms and Approvals** | UU `b3919637-5125-4d2d-a9f7-6d751835f537` or Name | Not seed ID `1000008` (Relationship Type on some builds) |
| Table **AbERP_ShiftChange** | UU `136fd0b7-e2b0-40a1-846f-1e198b8c232d` or TableName | |
| Button column **AbERP_CreateShiftChangeRequest** | ColumnName on that table | |
| Process **CreateRequestFromTemplate** | UU `3a8e1690-80f7-41b5-9ed9-96f5f3796823` or Value | Logilite class `com.logilite.template.request.process.RequestCopyFromTemplate` — **not** shipped by this ticket |
| Active Request Templates | `R_Request.IsTemplate='Y'` per Request Type | One template per type expected; popup filters by window `@R_RequestType_ID@` |

`00-preflight.sql` raises if table/window/tab/button missing. Process/template checks are in `05-*.sql` (raises if process/para missing).

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.shiftchange.form
psql -h localhost -U adempiere -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/00-preflight.sql \
  -f sql/01-virtual-status-and-submitted.sql \
  -f sql/02-prevent-dup-trigger.sql \
  -f sql/03-fix-columnsql-no-orderby.sql \
  -f sql/05-match-request-template-type.sql \
  -f sql/04-verify.sql
# Then WebUI: Cache Reset (or log out/in). No JAR / no OSGi restart.
```

**Rollback:** `sql/99-rollback.sql` then Cache Reset.

**Packs (Downloads):**

- Staging: `AbilityERP-ClientUpdate-SAW013_shift_change_form_enhancements-20260713\`
- Prod: `AbilityERP-ProdUpdate-SAW013_shift_change_form_enhancements-20260713\` (`01-APPLY.sql` + `99-ROLLBACK.sql` + `HOW-TO.txt`)

Do **not** tell the client to pull git / run `deploy.sh` as the primary path — pack is the deliverable.

## SQL order (what each file does)

| # | File | Purpose |
|---|------|---------|
| 00 | `00-preflight.sql` | Fail if Shift Change table/window/tab/Create button missing |
| 01 | `01-virtual-status-and-submitted.sql` | Physical read-only Status; add `AbERP_RequestSubmitted`; sync trigger on `R_Request`; backfill; Create DisplayLogic `@AbERP_RequestSubmitted@='N'` |
| 02 | `02-prevent-dup-trigger.sql` | BEFORE INSERT on `R_Request` blocks second active request for same Shift Change |
| 03 | `03-fix-columnsql-no-orderby.sql` | Clears leftover virtual ColumnSQL if any |
| 05 | `05-match-request-template-type.sql` | New AbERP val rule + CreateRequestFromTemplate para default/filter by `@R_RequestType_ID@` |
| 04 | `04-verify.sql` | Spot-check columns/fields/triggers/template para (optional; mismatch count can be slow on large DBs) |

## Portability / hard rules

- Look up targets by `*_UU` or stable Name — **never** hardcode `AD_*_ID` across clients.
- **Never** overwrite an existing client object’s `*_UU` when matching by name.
- Do **not** change shared val rule `R_Request Template` (UU `503d0fb8-d780-4a81-b2d3-081f2f3a25f5`) — used by mapping tables. This ticket adds a **new** rule instead.
- Do **not** use virtual ColumnSQL for Status/Submitted on this high-volume window (timeout on ~3.8k-row grids). Physical + trigger is intentional.

### AbERP-owned UUs (fixed)

| Object | UU |
|--------|-----|
| Element `AbERP_RequestSubmitted` | `a0130001-5a01-4e13-a013-000000000001` |
| Column `AbERP_RequestSubmitted` | `a0130002-5a01-4e13-a013-000000000002` |
| Field Request Submitted | `a0130003-5a01-4e13-a013-000000000003` |
| Val rule (template of window type) | `a0130004-5a01-4e13-a013-000000000004` |

### Existing objects (resolve, do not invent)

| Object | UU / Value |
|--------|------------|
| Window HCO Forms and Approvals | `b3919637-5125-4d2d-a9f7-6d751835f537` |
| Table AbERP_ShiftChange | `136fd0b7-e2b0-40a1-846f-1e198b8c232d` |
| Main tab | `a22481e4-c47f-43e3-ab9e-6c54a31ce2a1` |
| Process CreateRequestFromTemplate | `3a8e1690-80f7-41b5-9ed9-96f5f3796823` / Value `CreateRequestFromTemplate` |
| Process para RequestTemplate_ID | `13425072-7cf3-4cf0-8ff4-d3c1f00ef393` |

## AbilityERP Admin access

No new window/process/menu. Existing **HCO Forms and Approvals** + **Create Request From Template** access unchanged.

After install, confirm **Admin** and **AbilityERP Admin** can open the window and run Create (by role name on that build).

## WebUI smoke (acceptance)

1. Cache Reset / re-login.
2. Open **HCO Forms and Approvals** — grid loads (no “Timeout loading row 1”).
3. **WITH request:** Status matches Requests child; **Request Submitted** = Yes (read-only); **Create Request From Template** hidden.
4. **WITHOUT request:** Submitted = No; Create visible.
5. **Create flow:** set Request Type → Save → Create → popup **Request Template** defaults to **and lists only** that type → OK → Process completes → after refresh: Submitted = Yes, Create hidden, new Request type matches form.
6. Optional: second Create / forced second insert blocked (trigger exception).

## Safety / known non-goals

- Historical duplicate requests are **not** deleted.
- Sync trigger: `aberp_shiftchange_sync_from_request_trg` on `R_Request` (insert/update/delete) for AbERP_ShiftChange links only.
- Dup trigger: `aberp_shiftchange_prevent_dup_request_trg` BEFORE INSERT on `R_Request`.
- Some Summary / date fields may be `AD_Field.isupdateable=N` on HCO (pre-existing) — unrelated to this ticket.

## HCO

Follow `.cursor/rules/hco-deployment.mdc` and `Tickets/HCO_Deployment/`. Never change HCO `*_UU`. Learnings: `Tickets/HCO_Deployment/LEARNINGS.md`. Per-ticket variables: `NOTES.md` → **HCO Future Deployments variables**.

## External ticket text

`EXTERNAL-SUMMARY.md` (customer copy/paste).
