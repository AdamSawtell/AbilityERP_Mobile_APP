# SAW017 — External summary (customer / ticket paste)

**Status:** Delivered and smoke-tested on HCO Test (2026-07-13). Client / production update packs available (2026-07-14).

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| Booking Generator | Window | New **Bulk Generate Bookings** button (existing **Generate Bookings** unchanged) |
| Bulk Generate Bookings | Process | New — period, optional Activity block, Include Irregular / STR, Invoice Rule, DocAction |
| Generate Bookings | Process | Unchanged single-record path; bulk delegates to it |
| Service Booking | Orders | Created from selected STANDARD Booking Generators; Invoice Rule can be forced (default Immediate) |
| Menu | Menu | Bulk Generate Bookings (Admin / AbilityERP Admin) |

## What’s done

- Additive bulk/block Service Booking generation from Booking Generator Standards.
- Run-level Date From / Date To applied to each selected BG, then Generate Bookings runs per row.
- Defaults exclude Irregular Hrs and Short Term Respite/STA unless opted in; excludes templates, Programs of Support, Non Binding Offer doctypes, and `*Do Not Use*` activities.
- Invoice Rule Immediate can be forced on newly created bookings.
- HCO Test end-to-end: single generate SB `53324`; bulk STR `ok=3` with SBs `53325` / `53326` (Invoice Rule Immediate).

## Impact

Operators can generate a block (e.g. Short Term Accommodation or Day Program) for a period in one run instead of opening each Booking Generator line.

## How to test

1. Log in as **Admin** or **AbilityERP Admin**. Cache Reset after install.  
2. Open a STANDARD Booking Generator → **Generate Bookings** (Draft) for a short future period → confirm Service Booking + Invoice Rule Immediate.  
3. Menu or button **Bulk Generate Bookings**: set Date From/To, optional Activity, Include STR only if needed → OK.  
4. Confirm process log counts and new Service Bookings for that period.  
5. Confirm Irregular / STR stay out when Include flags are No.

## Access

**Admin** and **AbilityERP Admin** are granted process / window access in the install SQL.

## Caveats / out of scope

- Invoice Partner resetting on Booking Generator copy — separate issue.  
- Description month/year on Service Booking may remain a manual step.  
- Generate Bookings may report success with no new order if the period already has matching bookings/patterns.
