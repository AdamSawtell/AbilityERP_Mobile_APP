# SAW031 — Support day validate/save fix

**Status:** in-progress  
**Kind:** idempiere  
**GitHub:** [#31](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/31)  
**Related:** SAW009 (`support_day_pattern_number`)

## Goal

Fix Service Booking Line Validate/Save when **Support Start Day** / **Support End Day** are populated: values must not clear, save must succeed, Ready to Claim can auto-tick as before.

## Root cause

Flamingo `com.aberp.servicebooking.generator` model `MOrderLineAbERP.beforeSave` overwrites Support Start/End Day from `StartDate`/`EndDate` using `SimpleDateFormat("EEEE")` (weekday names like `Thursday`).

After SAW009 those columns are List **14 Day Roster Period** (values `1`..`15`). Weekday text is invalid → WebUI clears the fields and save fails with `Invalid value - Thursday - Reference_ID=…`.

## Fix

1. **Bytecode-patched generator JAR** — neutralize the two `setAbERPSupportStartDay/EndDay` calls in `beforeSave` (stackmap-safe `pop;pop;nop`).
2. **Optional overlay** `com.aberp.servicebooking.supportdays` ModelFactory — defense in depth (restore/sanitize weekday text).
3. **SQL cleanup** — null leftover weekday text; re-backfill from `AbERP_ServicePattern` where linked.

## Source paths

- `idempiere-plugins/com.aberp.servicebooking.supportdays/` (overlay + SQL + patch scripts)
- `idempiere-plugins/com.aberp.servicebooking.supportdays/patch/` (generator patch)
- `idempiere-plugins/com.aberp.servicebooking.supportdays/sql/06-cleanup-weekday-text.sql`
- `idempiere-plugins/com.aberp.servicebooking.supportdays/sql/07-verify-saw031.sql`

## Dependencies

Requires `com.aberp.servicebooking.generator` installed on the host.
