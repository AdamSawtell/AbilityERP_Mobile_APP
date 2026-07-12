# SAW011 ? Accept Shift Request

| | |
|--|--|
| **Status** | done |
| **Kind** | idempiere |
| **GitHub** | [#11](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/11) |
| **Slug** | `SAW011_accept_shift_request` |

## Deploy (other builds)

**? [`DEPLOY.md`](DEPLOY.md)** ? JAR + `install-accept-shift-request.sql` + restart.

## External ticket (copy/paste)

**? [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)** ? paste into the customer/external ticket (not for agents).

## Goal

On **Shift (Rostered) ? Response Log**, rostering officers can **Accept Shift Request** for a **Yes ? Request Shift (`REQ`)** row. That assigns the worker on the **Employee** tab, marks the log reviewed, and publishes the shift.

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.rosteredshift.process/`
- Process: `src/com/aberp/rosteredshift/process/AcceptShiftRequest.java`
- AD install: `sql/install-accept-shift-request.sql`
- Related: `sql/update-accept-button-displaylogic.sql`, package `README.md` / `deploy.sh`

## Dependencies (app)

None required for ERP accept. Mobile already writes REQ into Response Log; accept is WebUI-only assignment.

## Packs

- `AbilityERP-ClientUpdate-SAW011_accept_shift_request-<YYYYMMDD>`
- Thin prod: `AbilityERP-ProdUpdate-SAW011_accept_shift_request-<YYYYMMDD>` (JAR + `install-accept-shift-request.sql` + HOW-TO)
