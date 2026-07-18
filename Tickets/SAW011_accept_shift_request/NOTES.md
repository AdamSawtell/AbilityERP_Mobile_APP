# SAW011 notes

- Bundle: `com.aberp.rosteredshift.acceptrequest` **7.1.0.202607181500**
- Use only `sql/install-accept-shift-request.sql` (+ `sql/31-fix-accept-button-visibility.sql` for visibility hotfix)
- Published status: resolved via client-scoped SQL (`AD_Client_ID IN (0,?)`) — do not use LIMIT with `DB.getSQLValue`
- **UI:** Response Log → gear **Process** → **Accept Shift Request** (detail tabs put process buttons under Process, not as a form button)

## HCO Future Deployments variables

| Variable | Value (host `3.27.207.215` / `ip-172-31-4-174`, 2026-07-18) |
|---|---|
| Host | `3.27.207.215` (SSH key `HCObusiness.pem`) |
| Client | HCO - Disability and Community Services |
| Published `R_Status_ID` | **1000058** (name `Published`, category Shift Status) |
| Response Log tab | `AD_Tab_ID` 1000256 |
| Bundle | `com.aberp.rosteredshift.acceptrequest` **7.1.0.202607181500** ACTIVE |
| Process | `SHIFT_ACCEPT_REQUEST` |
| Smoke | Shift `1115309` / Doc `1108335` — Madura REQ accepted → staff + IsReviewed=Y (2026-07-18) |

### Install learnings (2026-07-18)

1. Hardcoded Published `1000040` is **Active** on HCO — resolve by name + client.
2. Detail-tab Button with IsToolbarButton=Y appears under **Process (gear)**, not as Save-and-Validate-style form button.
3. Displaylogic must use unquoted list Value `@AbERP_RosteredResponse@=REQ`; `@IsSuperseded@='N'` fails when NULL — use `!Y`.
4. `DB.getSQLValue` + LIMIT / multi-string binds failed; use CloseRosteringChat-style client-scoped SQL.
