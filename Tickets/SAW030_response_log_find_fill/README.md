# SAW030 — Response Log Find and Fill

| | |
|--|--|
| **Status** | in-progress |
| **Kind** | idempiere |
| **GitHub** | [#30](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/30) |
| **Slug** | `response_log_find_fill` |

## Deploy (other builds)

→ [`DEPLOY.md`](DEPLOY.md)

## External ticket (copy/paste)

→ [`EXTERNAL-SUMMARY.md`](EXTERNAL-SUMMARY.md)

## Goal

On **Shift (Rostered) → Response Log**, officers press **Find and Fill** (next to Reviewed). That opens the usual Staff Rostering Info (“Find & Fill”) with the response worker prefilled and the shift’s leave / overlap / familiar / matched checks. **OK** fills a vacant Employee slot and marks the response reviewed (Mode B).

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.rostering.staffinfo/`
- Process: `src/.../process/ResponseLogFindFill.java`
- Assign on OK: `ResponseLogFindFillAssign.java` + `StaffRosteringInfoWindow.saveSelectionDetail`
- AD: `sql/27-response-log-find-fill.sql`
- Bundle: `com.aberp.rostering.staffinfo` `1.1.0.202607181830`

## Dependencies

- SAW003 Staff Rostering Info (Info UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf`) must be installed
- Complementary to SAW011 Accept Shift Request (direct assign without Info)

## Packs

- `AbilityERP-ClientUpdate-SAW030_response_log_find_fill-<YYYYMMDD>`
- Thin prod: `AbilityERP-ProdUpdate-SAW030_response_log_find_fill-<YYYYMMDD>`
