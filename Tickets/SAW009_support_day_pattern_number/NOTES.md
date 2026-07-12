# SAW009 NOTES

## Investigation

- Booking Generator – Service Pattern uses `AbERP_ServicePattern.AbERP_RosterStartDay` / `AbERP_RosterEndDay` with List **14 Day Roster Period** (`ad_reference_uu` `5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd`). List **names** are already `01 - Sunday`, `02 - Monday`, … `09 - Monday`, etc.
- Service Booking Line (`C_OrderLine`) had **no** Support Start/End Day columns on seed. It does have `AbERP_ServicePattern_ID`.
- Shift/timesheet tables have String `AbERP_Support_Start_Day` storing weekday-only text (`Monday`) — out of scope for this ticket; not changed.
- Core `Weekdays` list (167) is weekday-only and must **not** be used for pattern day display.

## Approach

1. Add `c_orderline.aberp_support_start_day` / `aberp_support_end_day` (varchar).
2. AD columns/fields: List reference = same **14 Day Roster Period** as Service Pattern.
3. Backfill from linked `AbERP_ServicePattern` roster days only.
4. BEFORE INSERT/UPDATE trigger copies pattern days when Service Pattern ID is set/changed (covers Generate Bookings when it sets the FK).

## Historical records

Where `AbERP_ServicePattern_ID` is null, days stay null — no weekday→day-01 guessing.

## Residual blockers

- WebUI field smoke incomplete after Cache Reset session timeout on staging; SQL + trigger evidence green.
- Generate Bookings JAR not present on seed plugins; sync relies on trigger when `AbERP_ServicePattern_ID` is populated.
