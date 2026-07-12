# SAW009 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Service Booking Line support days  
**Internal ID:** SAW009_support_day_pattern_number

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Window** | Service Booking | Unchanged shell — line fields updated |
| **Tab** | Service Booking Line | Updated — Support Start Day / Support End Day fields |
| **Fields** | Support Start Day, Support End Day | **New/updated** — 14 Day Roster Period list (numbered days) |
| **Table** | `C_OrderLine` | Columns `AbERP_Support_Start_Day` / `AbERP_Support_End_Day` |
| **Window / Tab** | Booking Generator → Service Pattern Line | Unchanged — source of numbered day list |
| **Process** | *(none new)* | Sync via DB trigger when Service Pattern is linked |
| **Menu** | *(none new)* | — |

**Admin access:** AbilityERP Admin can open Service Booking and edit Support Start/End Day on lines.

---

## What’s been done

**Support Start Day** and **Support End Day** on Service Booking Lines now show the same numbered pattern-day labels used on Booking Generator Service Pattern Lines (for example `02 - Monday`, `09 - Monday`), so a 14-day roster can tell different Mondays apart.

## What changed

- Support Start/End Day fields on Service Booking Line use the **14 Day Roster Period** list (numbered days)
- When a Service Pattern is linked, days copy from the pattern
- Database trigger keeps days in sync when the pattern link is set or changed
- Historical lines without a pattern link are left alone (no guessing day 01 from weekday name)

## Impact

- Users editing Service Booking Lines and anyone reading support days for rostering/billing context
- No change to pricing, quantities, or recurrence engines beyond displaying/copying day values

## How to test

1. Log in as AbilityERP Admin.
2. Open **Service Booking → Service Booking Line**.
3. Confirm Support Start/End Day show numbered labels (not weekday-only).
4. Link a Service Pattern and confirm days copy correctly; change Start vs End independently.
5. On a 14-day pattern, confirm two different Mondays are distinguishable (e.g. day 2 vs day 9).
6. Confirm a line with no pattern link does not invent a false day.

## Notes / caveats

- After install: Cache Reset or log out/in (no iDempiere restart for SQL-only).
- If Generate Bookings JAR is missing on a host, day sync still works when the Service Pattern ID is set (trigger).
