# SAW013 — Shift Change form: auto status + prevent duplicate + match template

| | |
|--|--|
| **Status** | done (staging green on HCO Test; packs ready) |
| **Kind** | idempiere |
| **JAR** | No |
| **GitHub** | [#13](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/13) |
| **Slug** | `SAW013_shift_change_form_enhancements` |

## Deploy (other builds) — start here

**→ [`DEPLOY.md`](DEPLOY.md)** — ordered SQL, UUs, smoke, packs, rollback.

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

On **HCO Forms and Approvals** (`AbERP_ShiftChange`):

1. Status always mirrors the linked `R_Request` (no manual updates).
2. Staff can see whether a request was already submitted; Create Request cannot create duplicates.
3. Create Request popup **Request Template** matches the form’s **Request Type**.

## Source of truth

| Path | Role |
|------|------|
| `idempiere-plugins/com.aberp.shiftchange.form/` | Plugin home (SQL only) |
| `idempiere-plugins/com.aberp.shiftchange.form/sql/` | Install scripts `00`→`01`→`02`→`03`→`05`→`04` |
| `Tickets/SAW013_shift_change_form_enhancements/` | Agent/customer docs |

## Dependencies (app)

None.

## Approach (final)

| Item | Choice |
|------|--------|
| Auto Status | Physical read-only `R_Status_ID` + AFTER trigger on `R_Request` (virtual ColumnSQL timed out on large grids) |
| Submitted | Physical `AbERP_RequestSubmitted` + same sync + backfill |
| Hide Create | DisplayLogic `@AbERP_RequestSubmitted@='N'` |
| Dup block | BEFORE INSERT trigger on `R_Request` |
| Template match | New AbERP val rule on CreateRequestFromTemplate para only |

## Investigation summary

| Item | Finding |
|------|---------|
| Window | **HCO Forms and Approvals** UU `b3919637-…` (not seed ID 1000008) |
| Table | `AbERP_ShiftChange` UU `136fd0b7-…` |
| Link | `R_Request.AD_Table_ID` + `Record_ID` = Shift Change PK |
| Create process | Logilite `CreateRequestFromTemplate` (prerequisite, not in this pack) |

## Packs

- `Downloads\AbilityERP-ClientUpdate-SAW013_shift_change_form_enhancements-20260713\`
- `Downloads\AbilityERP-ProdUpdate-SAW013_shift_change_form_enhancements-20260713\`
