# SAW015 — Notes

## Pattern

Service Booking **Copy Lines** = `C_Order.CopyFrom` button → `org.compiere.process.CopyFromOrder` with Search parameter for source order.  
SAW015 mirrors that: header button → `CopyDatesFrom` with Search parameter `AbERP_Skip_Dates_ID`.

## HCO discovery (2026-07-13)

| Object | UU |
|--------|-----|
| Skip Dates window | `b3037901-e883-42f2-8e6d-c8e759ca91cd` |
| Header tab | `4224ab0d-fa68-44ac-9371-eb5fd100c3b3` |
| Dates tab | `d07ecead-7f5f-43e3-beef-57a4068cebcb` |
| Table AbERP_Skip_Dates | `88130ae9-2aac-4c86-9c98-f94b272af212` |
| Table AbERP_Dates | `bac8f234-c300-45f5-b8bb-5f7c7a0a2152` |
| Process (AbERP-owned) | `15a01501-c0d4-4f01-8e15-000000000001` |

Dates columns copied: StartDate, EndDate, Description, IsActive (+ client/org from target).

## Design decisions

- New OSGi bundle `com.aberp.skipdates.copyfrom` (do not reuse other AbERP symbolic names).
- Window button `IsToolbarButton = B` for visible labeled button (Service Booking uses toolbar `Y`; AbERP Accept Shift uses `B`).
- `showhelp = Y` + Help text = date-review warning; success message repeats warning + count.
- Val rule excludes current Skip Dates from source picker.
- `nextidfunc` for AD IDs (HCO `nextid` is OUT-param only).

## HCO smoke (2026-07-13)

- Bundle ACTIVE `com.aberp.skipdates.copyfrom_7.1.0.202607131830`.
- Target **SAW015 UAT Copy Test** (id 1000014): 0 → **12** lines from **Public Holidays 2025+2026**.
- Source still 12; overlapping date IDs = 0.
- Message: `Copied 12 date record(s) from "Public Holidays 2025+2026". The copied records contain specific dates...`

## Ops note

SAW012 purge DELETE sessions had saturated `max_connections` during install; waiting DELETE backends were terminated to free slots for smoke. Re-run SAW012 purge off-peak if still needed.

## HCO Future Deployments variables

| Item | Value |
|------|--------|
| Host | `32.236.127.117` |
| WebUI | `http://32.236.127.117/webui/` |
| SSH | `ubuntu@32.236.127.117` · key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| DB | `idempiere` / `adempiere` / `flamingo` |
| Skip Dates window UU | `b3037901-e883-42f2-8e6d-c8e759ca91cd` |
| Process UU | `15a01501-c0d4-4f01-8e15-000000000001` |
| Column UU | `15a01503-c0d4-4f01-8e15-000000000003` |
| Field UU | `15a01504-c0d4-4f01-8e15-000000000004` |
| JAR | `com.aberp.skipdates.copyfrom_7.1.0.202607131830.jar` |
