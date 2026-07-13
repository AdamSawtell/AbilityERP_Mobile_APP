# SAW013 — Shift Change form: auto status + prevent duplicate requests

| | |
|--|--|
| **Status** | staging green (packs ready) |
| **Kind** | idempiere |
| **GitHub** | [#13](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/13) |
| **Slug** | `SAW013_shift_change_form_enhancements` |
| **HCO host** | `32.236.127.117` (same as SAW012) |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)**

## External ticket (copy/paste)

**→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)**

## Goal

On **HCO Forms and Approvals** (`AbERP_ShiftChange`):

1. Status always mirrors the linked `R_Request` (no manual updates).
2. Staff can see whether a request was already submitted; Create Request cannot create duplicates.
3. Create Request popup **Request Template** matches the form’s **Request Type**.

## Source of truth

- `idempiere-plugins/com.aberp.shiftchange.form/`
- SQL only (no JAR)

## Dependencies (app)

None.

## Investigation summary

| Item | Finding |
|------|---------|
| Window | **HCO Forms and Approvals** (not seed ID 1000008 — that is Relationship Type on HCO) |
| Window UU | `b3919637-5125-4d2d-a9f7-6d751835f537` |
| Table | `AbERP_ShiftChange` UU `136fd0b7-e2b0-40a1-846f-1e198b8c232d` |
| Link | `R_Request.AD_Table_ID` = Shift Change table + `Record_ID` = `AbERP_ShiftChange_ID` |
| Status store | `R_Request.R_Status_ID` (source of truth); form had manual `AbERP_ShiftChange.R_Status_ID` |
| Create process | Logilite `CreateRequestFromTemplate` on button `AbERP_CreateShiftChangeRequest` |
| Duplicates | Many Shift Change rows already have 2–11 active requests on HCO Test |

## Approach

Virtual column for Status + virtual **Request Submitted** (Option A) + hide Create button (Option B) + INSERT trigger hard-block.
