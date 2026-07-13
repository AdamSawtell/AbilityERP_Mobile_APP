# SAW015 — External summary (customer / ticket paste)

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| Skip Dates (`AbERP_Skip_Dates`) | Window | New **Copy Dates From** button on the header |
| Dates (`AbERP_Dates`) | Tab / table | Lines can be copied from another Skip Dates header into the current one |
| Copy Dates From | Process | Selects a source Skip Dates record; copies date lines; warns to review dates/years; reports how many were copied |

## What’s done

Users can copy all date lines from an existing Skip Dates record into a newly created Skip Dates header, instead of re-entering each date manually.

## What changed (behaviour)

After saving a Skip Dates header, run **Copy Dates From**, pick an existing Skip Dates record, and the system copies every date line to the current header. The source record is not changed. The process shows a clear reminder that copied values are specific calendar dates and should be reviewed (update years, remove or add dates as needed). It reports how many dates were copied. You can then edit or delete lines on the new record.

## Impact

Staff who maintain holiday / exclusion calendars can reuse an existing Skip Dates set as a starting point.

## How to test

1. Log into WebUI as Admin (or AbilityERP Admin).
2. Open **Skip Dates** → create and save a new header (or open an empty one).
3. Click **Copy Dates From** → select a source Skip Dates that already has dates (for example Public Holidays).
4. Confirm the review warning appears.
5. Confirm the success message includes the number copied and the Dates tab shows those lines.
6. Open the source record and confirm its dates are unchanged.
7. Edit or delete a copied date on the new record.

## Access

**AbilityERP Admin** and operational **Admin** can run **Copy Dates From** after install. Log out/in (or Role Access Update) if the button is missing.

## Caveats

Copied lines keep the **same calendar date values** as the source. Always review and update the year (and any non-applicable dates) before using the new Skip Dates record in processing. After install: Cache Reset or logout/in.
