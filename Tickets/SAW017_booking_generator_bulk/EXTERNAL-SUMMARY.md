# SAW017 — External summary (customer / ticket paste)

**Status:** Scope accepted for development planning. Not yet delivered in WebUI.

## Windows / processes / objects affected (planned)

| Object | Type | Planned change |
|--------|------|----------------|
| Booking Generator | Window | Bulk / block generation entry (process and/or Info Window selection) |
| Booking Generator record | Table | Likely type/category or “include in bulk generation” attribute so POS / Quotes can be excluded |
| Generate Bookings (existing) | Process | Remains for single-record use; bulk run will reuse this behaviour where possible |
| New bulk generate process | Process | Period once per run; block and/or tick selection; Standards-only defaults |
| Service Booking | Window / orders | Created in bulk from selected generators; Invoice Rule behaviour defined (e.g. Immediate) |

## What’s done

Requirements captured. Existing AbilityERP generators (timesheet / invoice / roster style and current single-record Generate Bookings) reviewed for patterns. Development approach drafted: discover host Generate* JARs, add BG filter attribute if needed, implement bulk/block process that delegates to existing generation logic, with run-level dates and exclusion rules.

## What will change (behaviour when delivered)

Staff will generate Service Bookings for a month (or period) in blocks (e.g. SIL / DO / IHS) and/or by ticking Booking Generator lines, without setting dates on every line. Irregular Hours and Short Term Respite stay out of the default bulk run. Only Standards (not Quotes, Programs of Support, templates) are included. Invoice Rule on generated bookings will follow the agreed rule (e.g. remain Immediate). Waiting-on-plan, Day Options/Tri-States, and client-exit cases can be skipped or excluded per process rules/guidance.

## Impact

Removes the ~206-line manual Generate Bookings loop (hours to days of admin time). Keeps flexibility for mid-month plan changes via dates on the Booking Generator record.

## How to test (when delivered)

1. Log in as Admin / AbilityERP Admin.  
2. Run bulk generate for one block with a single period.  
3. Confirm expected Standards Service Bookings only.  
4. Confirm Invoice Rule.  
5. Confirm Irregular / STR not generated unless selected.  
6. Spot-check a mid-month date override and an exited client skip.

## Access

**AbilityERP Admin** will receive access to any new process / Info Window / button.

## Caveats / out of scope

- Invoice Partner resetting on Booking Generator copy — separate issue.  
- Description month/year on Service Booking may remain a manual admin step unless added later.  
- Vendor estimate and deploy cycle for Flamingo Logic / Logilite work to be confirmed.
