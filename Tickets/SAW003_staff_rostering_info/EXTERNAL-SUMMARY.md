# SAW003 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Shift (Rostered) → Employee staff search  
**Internal ID:** SAW003_staff_rostering_info

## What’s been done

The **Employee (User) / Agency Staff** search used when assigning people on a rostered shift has been rewritten for speed and clearer filtering. Officers see better leave / overlap handling, optional matching to related rostering needs (credentials, gender, restricted employee), and a leaner results line.

## What changed

- Faster staff search (simpler query behind the scenes)
- Name search automatically wraps wildcards (less typing of `%`); field labelled **Staff Name**
- When opened from a shift, people on approved leave over that period or already rostered on an overlapping shift are hidden by default
- **Show Unmatched Staff** / needs matching against related rostering needs
- Banner summarising shift context and needs
- Related Info (shifts / credentials / alerts) enabled
- Contact pick fills business partner (and org behaviour as designed)
- Result grid decluttered: **BP Name**, **Status**, **Business Partner**, and **Agency Staff – Approved for shifts** hidden from the line (Agency Staff remains available as a filter)
- Selected rows in the search results stay display-only so officers do not edit staff fields from the picker

## Impact

- Rostering officers assigning staff on **Shift (Rostered) → Employee**
- Day-to-day: quicker search, fewer unsuitable people in the default list, less duplicate columns on the pick list
- Does **not** change how Accept Shift Request works (that is a separate ticket)
- **AbilityERP Admin** retains full access to the Info Window and related features

## How to test

1. Log in as AbilityERP Admin or Rostering Officer.
2. Open a **Shift (Rostered)** → **Employee** → open the staff search.
3. Search by name without typing `%` — results should still appear.
4. Confirm people on approved leave for the shift window are hidden unless you opt in.
5. With related needs on the shift, confirm default list prefers matching staff; toggle **Show Unmatched Staff** if present.
6. Confirm the results line does **not** show BP Name, Status, Business Partner, or Agency Staff columns (Agency Staff may still appear as a filter above the grid).
7. Pick a contact and confirm BP fills on the employee line.
8. Open Related Info links if used on your build.

## Notes / caveats

- Requires the existing Staff Rostering Info Window to already be present on the client.
- Install includes a small Java plugin — iDempiere restart is required, then log out/in or Cache Reset.
