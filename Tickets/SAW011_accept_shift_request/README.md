# SAW011 — Accept Shift Request (+ Find and Fill)

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#11](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/11) |
| **Slug** | `accept_shift_request` |

## Deploy (other builds)

→ [`DEPLOY.md`](DEPLOY.md)

## External ticket (copy/paste)

→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)

## Goal

On **Shift (Rostered) → Response Log**, rostering officers can:

1. **Accept Shift Request** — for a **Yes – Request Shift (`REQ`)** row: assign that worker to a vacant Employee line, mark reviewed, publish the shift.
2. **Find and Fill** — open the usual Staff Rostering Info with the response worker prefilled and shift checks; **OK** fills a vacant Employee slot and marks reviewed (same vacancy/publish rules).

## Source of truth

**Accept**

- Plugin: `idempiere-plugins/com.aberp.rosteredshift.process/`
- Process: `AcceptShiftRequest` / `SHIFT_ACCEPT_REQUEST`
- AD: `sql/install-accept-shift-request.sql` (+ displaylogic hotfixes)

**Find and Fill** (same ticket — builds on Accept)

- Plugin: `idempiere-plugins/com.aberp.rostering.staffinfo/`
- Process: `ResponseLogFindFill` / `AbERP_ResponseLog_FindFill`
- AD: `sql/27-response-log-find-fill.sql`
- Bundle: `com.aberp.rostering.staffinfo` `1.1.0.202607181830+`

## Dependencies

- SAW003 Staff Rostering Info (Find & Fill Info Window) for the Find and Fill button
- Mobile already writes REQ into Response Log; both actions are WebUI assignment

## Packs

- `AbilityERP-ClientUpdate-SAW011_accept_shift_request-<YYYYMMDD>`
- Thin prod: `AbilityERP-ProdUpdate-SAW011_accept_shift_request-<YYYYMMDD>`

## Note

GitHub [#30](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/30) was opened by mistake for Find and Fill; work lives under SAW011. Folder `Tickets/SAW030_response_log_find_fill/` is a redirect stub only.
