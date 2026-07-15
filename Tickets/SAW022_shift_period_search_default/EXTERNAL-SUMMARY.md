# SAW022 — External summary (customer / ticket paste)

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| Shift (Rostered) | Window | Opens Find with saved query **\* Current Pay Period** selected by default |
| \* Current Pay Period | Saved query | New shared default — filters shifts in today’s active pay period |
| Roster Period (field) | AD Field | Best-effort Find default value (query is what drives the filter) |

No new menus, processes, or buttons. No JAR.

## What’s done

Opening **Shift (Rostered)** now defaults the Lookup saved query to the **current pay period**, so the first search shows this fortnight’s shifts instead of the full historic list.

## What changed (behaviour)

- **Before:** Find opened blank / could load a very large historic set.
- **After:** Saved query **\* Current Pay Period** is selected on open. Click OK to list the current period. Switch to **\* New Query \*\*** or any other saved query (location etc.) for other ranges.

## Impact

Faster day-to-day rostering lookup. No change to how shifts are saved, generated, or assigned. Existing location/other saved queries unchanged.

## How to test

1. Log into WebUI as Admin (or AbilityERP Admin).
2. Open **Shift (Rostered)**.
3. Confirm Saved Query shows **\* Current Pay Period**.
4. OK — grid should be current-period shifts only (not the full 100k history).
5. Switch to **\* New Query \*\*** or a location query — broader / other filters work.

## Access

Uses the existing Shift (Rostered) window. **AbilityERP Admin** / **Admin** already have access; no new grants.

## Caveats

After install: **Cache Reset** or log out and back in.
