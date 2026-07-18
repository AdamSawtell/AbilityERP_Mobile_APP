# SAW011 notes

- Bundle: `com.aberp.rosteredshift.acceptrequest`
- Use only `sql/install-accept-shift-request.sql` (name-based role grants)
- Do not use `grant-process-access-roles.sql` / `register-accept-shift-request.sql` on other builds (hardcoded role IDs)
- Published status: **resolved at runtime** by name `Published` under category `Shift Status` (no hardcoded `R_Status_ID`)

## HCO Future Deployments variables

| Variable | Value (host `3.27.207.215` / `ip-172-31-4-174`, 2026-07-18) |
|---|---|
| Host | `3.27.207.215` (SSH key `HCObusiness.pem`) |
| Client | HCO - Disability and Community Services |
| Published `R_Status_ID` | **1000058** (name `Published`, value `1000021`, category Shift Status) — **not** 1000040 (that ID is Active here) |
| Response Log tab | `AD_Tab_ID` 1000256 on Shift (Rostered) |
| Roles granted | AbilityERP Admin, Admin, Rostering, Rostering TL (no role named Rostering Officer on this build) |
| Bundle | `com.aberp.rosteredshift.acceptrequest` **7.1.0.202607181300** ACTIVE |
| Process | `SHIFT_ACCEPT_REQUEST` → `com.aberp.rosteredshift.process.AcceptShiftRequest` |

### Install learnings (2026-07-18)

1. Hardcoded Published `1000040` would have set status to **Active** on HCO — fixed in Java via name lookup.
2. Grant list must include **Admin** / **Rostering** / **Rostering TL** (HCO naming), not only Rostering Officer.
3. PostgreSQL rejected `UPDATE ad_field f … JOIN ad_column c ON c.ad_column_id = f.ad_column_id` — fixed to comma-join `ad_column` in WHERE.
