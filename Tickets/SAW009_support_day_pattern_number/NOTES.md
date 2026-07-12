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

## HCO Future Deployments variables

Recorded from HCO Test (`32.236.127.117`) on 2026-07-12. **Do not change HCO `*_UU` values.**

| Variable | AbilityERP pack / seed | HCO observed | Notes |
|----------|------------------------|--------------|-------|
| Service Booking Line tab UU | `8b044105-bc30-4f81-b0d6-a45835d82f98` | **same** (local tab `1000137`) | Preflight OK |
| 14 Day Roster Period UU | `5ec1b0b5-7ce8-43dc-bf9d-77bc2d7afbbd` | **same** (local ref `1000211`) | List **names** on HCO start `01 - Monday` (not Sunday) — use list as-is |
| Element Start/End UUs | `ac9cf459-…` / `fbe588b0-…` | **same** | |
| `AD_Column` Start UU (owned) | `c0a90001-50a9-4009-a001-000000000001` | **kept** `0ca9788b-6a9e-4356-9748-792ca12f861b` | Column already existed (String weekday text) |
| `AD_Column` End UU (owned) | `c0a90002-50a9-4009-a001-000000000002` | **kept** `47d85407-dbba-4c79-995a-b6cbbe6f4861` | Same |
| Physical columns | varchar(5) add if missing | already varchar(100) | Do not shrink |
| Pre-existing data | n/a | weekday names (`Monday`…) | Backfill from pattern → values `1`..`15` |
| Field Start UU | owned `c0a90003-…` | `bd2491dc-e171-43d3-963a-265b71015ae5` | New field; resolve by tab+column |
| Field End UU | owned `c0a90004-…` | `4ab4e10e-1f72-4dc3-9c60-90cec70a78fe` | New field; resolve by tab+column |
| Service Booking window | — | `1000075` / UU `5ba3cde5-efad-435f-a606-a1e1ed22e542` | Smoke doc example `53305_17/07/2026` showed `13 - Saturday` |

### Process fixes from HCO

- `01-add-support-day-columns.sql`: if column exists by **ColumnName**, update List reference only — **never overwrite `ad_column_uu`**.
- `02-add-fields.sql`: if field exists on tab for that column, update display — **never overwrite `ad_field_uu`**.

### HCO install outcome

- Pass: SQL + trigger + backfill 48019 lines; WebUI Support Start/End Day = `13 - Saturday` on Service Booking Line.
