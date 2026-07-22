# SAW031 — External summary (customer ticket)

## Windows / processes / objects affected

| Type | Name | Notes |
|------|------|--------|
| **Window** | Service Booking | Existing |
| **Tab** | Service Booking Line | Validate + Support Start/End Day behaviour fixed |
| **Fields** | Support Start Day, Support End Day, Validated, Ready to Claim | Existing (SAW009 list format) |
| **Table** | `C_OrderLine` | Persistence no longer overwritten with weekday names on save |
| **Plugin** | `com.aberp.servicebooking.generator` (patched) | beforeSave no longer writes `Monday`/`Tuesday`/… into Support Day fields |

## What’s done

Fixed a regression introduced when Support Start/End Day moved to the numbered **14 Day Roster Period** list (SAW009). Validating a booking line no longer clears those fields or blocks save.

## What changed (behaviour)

- On Validate/Save, Support Start Day and Support End Day keep their pattern-day values (e.g. `03 - Wednesday`).
- Save completes successfully.
- Ready to Claim can still auto-tick when the booking’s Ready to Claim Rule says so after a successful validate/save.
- Historic rows that still had weekday text (`Monday`, …) were cleaned and, where a Service Pattern is linked, refilled from the pattern.

## Impact

Users validating Service Booking Lines with Support Start/End Day populated can complete validation again. Affects Service Booking Line maintenance only.

## How to test

1. Open a Service Booking with unvalidated lines that show Support Start/End Day values.
2. Tick **Validated** on a line and Save.
3. Confirm Support days remain, the line saves, and Ready to Claim updates per your Ready to Claim Rule when expected.
4. Optional: confirm a line with blank Support days still validates as before.

## Access

AbilityERP Admin (and operational Admin on HCO) already needs Service Booking window access — no new process/window grants for this fix.

| Access | Name | Search key |
|--------|------|------------|
| Window | Service Booking | — |
