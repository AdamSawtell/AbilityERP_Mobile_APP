# SAW011 notes

- Bundle: `com.aberp.rosteredshift.acceptrequest` **7.1.0.202607181500**
- Use `sql/install-accept-shift-request.sql` (+ `sql/33-accept-displaylogic-name.sql` for toolbar/Process + Admin grants)
- Published status: resolved via client-scoped SQL (`AD_Client_ID IN (0,?)`) — do not use LIMIT with `DB.getSQLValue`
- **UI:** Response Log record → **Accept Shift Request** Window button (same pattern as Employee **Clock In**). Visible in form view and in **Grid Toggle** (`isdisplayedgrid=Y`). `IsToolbarButton=N`.
- **Function:** Accept assigns Response Log `AbERP_User_Contact_ID` → Employee tab staff line, sets IsReviewed, publishes shift.
- **Access:** always grant process to **Admin** and **AbilityERP Admin** (plus Rostering roles when present).
- Hotfix SQL: `sql/34-accept-window-button-form-grid.sql` (after Cache Reset).

## HCO Future Deployments variables

| Variable | Value (host `3.27.207.215` / `ip-172-31-4-174`, 2026-07-18) |
|---|---|
| Host | `3.27.207.215` (SSH key `HCObusiness.pem`) |
| Client | HCO - Disability and Community Services |
| Published `R_Status_ID` | **1000058** (name `Published`, category Shift Status) |
| Response Log tab | `AD_Tab_ID` 1000256 |
| Bundle | `com.aberp.rosteredshift.acceptrequest` **7.1.0.202607181500** ACTIVE |
| Process | `SHIFT_ACCEPT_REQUEST` |
| Smoke | Shift `1115309` Madura; shift `1110644` / Doc `1103676` Navroop Gill REQ → Employee + IsReviewed=Y (2026-07-18, Admin) |

### Install learnings (2026-07-18)

1. Hardcoded Published `1000040` is **Active** on HCO — resolve by name + client.
2. Response Log Accept is a **Window button** (`IsToolbarButton=N`) like Employee Clock In — on the record in form view and in Grid Toggle (`isdisplayedgrid=Y`). Do not use `Y` (Process-menu only).
3. Displaylogic: list Value `@AbERP_RosteredResponse@=REQ`; `@IsSuperseded@='N'` fails when NULL — use `!Y`. Do not match list Name with hyphens in DisplayLogic.
4. `DB.getSQLValue` + LIMIT / multi-string binds failed; use CloseRosteringChat-style client-scoped SQL.
5. Admin process access is mandatory for this feature (and any new process).
