# SAW022 — External summary (customer / ticket paste)

## Windows / processes / objects affected

| Object | Type | Change |
|--------|------|--------|
| Shift (Rostered) | Window | Opens Find with saved query **\* Current Pay Period** selected by default |
| \* Current period - available only | Saved query | Default Find — current pay period and Showing As Available = Y |
| Shift (Rostered) header tab | Tab Help / Description | Explains the default Find behaviour |
| Roster Period (field) | AD Field | Best-effort Find default value (query is what drives the filter) |

No new menus, processes, or buttons. No JAR.

## What’s done

Opening **Shift (Rostered)** now defaults Find to **\* Current period - available only** (current pay period and Showing As Available = Y), with Help text on the tab explaining how to widen the search.

## What changed (behaviour)

- **Before:** Find opened blank / could load a very large historic set.
- **After:** Saved query **\* Current Pay Period** is selected on open. Click OK to list the current period. Switch to **\* New Query \*\*** or any other saved query (location etc.) for other ranges.

## Impact

Faster day-to-day rostering lookup. No change to how shifts are saved, generated, or assigned. Existing location/other saved queries unchanged.

## How to test

1. Log into WebUI as Admin (or AbilityERP Admin).
2. Open **Shift (Rostered)**.
3. Confirm Saved Query shows **\* Current period - available only**.
4. OK — grid should be available shifts in the current period only.
5. Switch to **\* New Query \*\*** or a location query — broader / other filters work.

## Access

Uses the existing Shift (Rostered) window. **AbilityERP Admin** / **Admin** already have access; no new grants.

## Caveats

After install: **Cache Reset** or log out and back in.
