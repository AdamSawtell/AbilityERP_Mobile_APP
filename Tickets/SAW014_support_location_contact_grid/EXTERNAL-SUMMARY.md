# SAW014 — External summary (customer / ticket paste)

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| Support Location | Window | Email / Phone / Phone 2 (and Location Name / Location Is Active) now fill in Grid View for all rows |
| AbERP_Support_Location | Table columns (virtual) | ColumnSQL changed from `@SQL=` to correlated subquery against `C_BPartner_Location` |

No new menus, processes, or buttons.

## What’s done

Fixed Support Location so contact fields show for every grid row when the window loads, without needing to click each record first.

## What changed (behaviour)

Previously Email, Phone, and Phone 2 only appeared after you selected a row. They now display for all loaded rows, reading live from the linked Business Partner Location. Blank stays blank when the location has no email/phone.

## Impact

Rostering / support staff browsing Support Location in grid can see contact details at a glance. No change to how locations are edited or saved.

## How to test

1. Log into WebUI as Admin (or AbilityERP Admin).
2. Open **Support Location** in Grid View.
3. Without selecting a row, confirm Email / Phone / Phone 2 show for locations that have contact details (e.g. “2 Ware Close”).
4. Click through several rows — values remain correct.
5. Confirm locations with no contact still show empty fields.

## Access

Uses the existing Support Location window. **AbilityERP Admin** (and HCO **Admin**) already have access; no new grants required.

## Caveats

After install: run **Cache Reset** or log out and back in so the Application Dictionary change is picked up.
