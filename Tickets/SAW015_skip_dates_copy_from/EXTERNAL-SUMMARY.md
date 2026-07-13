# SAW015 — External summary (customer / ticket paste)

> **Status:** In progress — not ready for customer paste until staging UAT pass.

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| AbERP_Skip_Dates (Skip Dates) | Window | New **Copy Dates From** process / button on header |
| AbERP_Dates (Dates) | Tab / table | Lines copied from a selected source Skip Dates header into the current header |
| Copy Dates From | Process | Selects source Skip Dates; copies date lines; warns to review dates/years; reports count copied |

## What’s done

*(Fill after delivery.)* Add ability to copy date lines from an existing Skip Dates record into a newly created Skip Dates header, instead of re-entering each date manually.

## What changed (behaviour)

*(Planned.)* After saving a new Skip Dates header, the user runs **Copy Dates From**, picks an existing Skip Dates record, and the system copies all date lines to the new header. Source records stay unchanged. The process warns that copied dates are specific calendar dates and must be reviewed (year updates, removals, additions). It reports how many dates were copied. Users can then edit or delete lines on the new record.

## Impact

Users who maintain Skip Dates (holiday / exclusion calendars) can reuse an existing set of dates as a starting point.

## How to test

1. Log into WebUI as Admin (or AbilityERP Admin).
2. Open **Skip Dates** → create and save a new header.
3. Run **Copy Dates From** → select a source Skip Dates that already has dates.
4. Confirm the review warning appears.
5. Confirm the Dates tab shows the copied lines and the process message includes the count.
6. Open the source record and confirm its dates are unchanged.
7. Edit or delete a copied date on the new record.

## Access

**AbilityERP Admin** (and operational **Admin** where used) can run **Copy Dates From** after install. Log out/in (or Role Access Update) if the button is missing after deploy.

## Caveats

Copied lines keep the **same calendar date values** as the source. Always review and update the year (and any non-applicable dates) before using the new Skip Dates record in processing.
