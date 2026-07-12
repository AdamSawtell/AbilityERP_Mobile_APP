# SAW014 — Notes

## Root cause (confirmed on HCO 2026-07-13)

| Column | UU | Was |
|--------|-----|-----|
| AbERP_Email | `bd54d23d-44b6-42d7-b8c8-30b3e7b826e6` | `@SQL=SELECT Email FROM C_BPartner_Location WHERE … @C_BPartner_Location_ID:0@` |
| AbERP_Phone | `5f9a40e5-248b-48bd-848f-532ae4601006` | same pattern for Phone |
| AbERP_Phone2 | `f41c821a-90fb-4b8b-95c6-8bf2f181f8e7` | same pattern for Phone2 |
| AbERP_LocationName | `21b6490e-5aea-4035-b64c-c45c7cc05161` | same `@SQL=` defect |
| AbERP_Location_IsActive | `a77b2962-807c-464b-a8f5-1871ffd9fd1c` | same `@SQL=` defect |

In iDempiere 7, `@SQL=` virtual columns are evaluated only for the current/selected row in Grid View. Correlated subquery `ColumnSQL` (no `@SQL=`) is included in the tab query for every row — already used successfully on this table for `AbERP_Location_Address`, `AbERP_Occupant_Type`, etc.

## Solution chosen

Convert to subquery ColumnSQL reading live from `C_BPartner_Location`. No physical columns, no view rewrite of the window table (would complicate insert/update), no data duplication.

## HCO smoke (2026-07-13)

1. Applied `00-preflight` + `01-fix-contact-columnsql` + `04-verify` — all five columns `OK subquery`.
2. Cache Reset via WebUI.
3. Opened **Support Location** Grid View (35 rows).
4. Unselected rows (e.g. Unit 4 Lehmann, Unit 3 Lehmann) showed Email / Phone / 2nd Phone matching `C_BPartner_Location`.
5. Rows with no BP contact (The Shed, Glenlea 124) correctly blank.
6. Swinley 14: phone only in DB and grid — matches.

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `32.236.127.117` |
| WebUI | `http://32.236.127.117/webui/` |
| SSH | `ubuntu@32.236.127.117` · key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| DB | `idempiere` / `adempiere` / `flamingo` |
| Window UU | `6ef3c558-3ec8-4f0c-be40-89f35d8acebf` |
| Table UU | `4ed40b98-ca31-4404-a20b-ea9000d5c51d` |
| Email col UU | `bd54d23d-44b6-42d7-b8c8-30b3e7b826e6` |
| Phone col UU | `5f9a40e5-248b-48bd-848f-532ae4601006` |
| Phone2 col UU | `f41c821a-90fb-4b8b-95c6-8bf2f181f8e7` |
