# SAW003 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Shift (Rostered) → Employee staff search  
**Internal ID:** SAW003_staff_rostering_info

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Info Window** | Employee (User) / Agency Staff Rostering Info | Updated — rewrite, criteria, needs-match, UX |
| **Window** | Shift (Rostered) | Unchanged structure — uses updated Info from Employee tab search |
| **Tab** | Employee (on Shift Rostered) | Uses the updated Info Window / callouts |
| **Process** | *(none new)* | — |
| **Menu** | *(none new)* | — |
| **Related Info** | Rostered Shift / Credentials / Alerts | Enabled on this Info Window |

**Admin access:** AbilityERP Admin can open Shift (Rostered) and use the staff Info search.

---

## What’s been done

The **Employee (User) / Agency Staff** search used when assigning people on a rostered shift has been rewritten for speed and clearer filtering. Officers see better leave / overlap handling and optional matching to related rostering needs (credentials, gender, restricted employee).

## What changed

- Faster staff search (simpler query behind the scenes)
- Name search automatically wraps wildcards (less typing of `%`)
- When opened from a shift, people on approved leave over that period or already rostered on an overlapping shift are hidden by default
- **Show Unmatched Staff** / needs matching against related rostering needs
- Banner summarising shift context and needs
- Related Info (shifts / credentials / alerts) enabled
- Contact pick fills business partner (and org behaviour as designed)

## Impact

- Rostering officers assigning staff on **Shift (Rostered) → Employee**
- Day-to-day: quicker search, fewer unsuitable people in the default list
- Does **not** change Accept Shift Request (separate ticket SAW011)

## How to test

1. Log in as AbilityERP Admin or Rostering Officer.
2. Open a **Shift (Rostered)** → **Employee** → open the staff search.
3. Search by name without typing `%` — results should still appear.
4. Confirm people on approved leave for the shift window are hidden unless you opt in.
5. With related needs on the shift, confirm default list prefers matching staff; toggle **Show Unmatched Staff** if present.
6. Pick a contact and confirm BP fills on the employee line.
7. Open Related Info links if used on your build.

## Notes / caveats

- Requires the existing Staff Rostering Info Window to already be present on the client.
- Install includes a small Java plugin — iDempiere restart is required, then log out/in or Cache Reset.
