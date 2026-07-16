# SAW003 — External ticket update (copy/paste)

**Status:** Ready for client install (JAR **1.1.0.2026071517** on staging and HCO Test)  
**Area:** iDempiere — Shift (Rostered) → Employee staff search  
**Internal ID:** SAW003_staff_rostering_info

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Info Window** | Employee (User) / Agency Staff Rostering Info | Updated — rewrite, criteria, needs-match, UX, lean grid, unmatched credential AND filter |
| **Window** | Shift (Rostered) | Unchanged structure — uses updated Info from Employee tab search |
| **Tab** | Employee (on Shift Rostered) | Uses the updated Info Window / callouts |
| **OSGi plugin** | `com.aberp.rostering.staffinfo` `1.1.0.2026071517` | Java Info + callout (restart required) |
| **Process** | *(none new)* | — |
| **Menu** | *(none new)* | — |
| **Related Info** | Roster period shifts / Leave / Alerts / Credentials | Enabled on this Info Window |

**Admin access:** AbilityERP Admin / Admin / Rostering can open Shift (Rostered) and use the staff Info search.

---

## What’s been done

The **Employee (User) / Agency Staff** search used when assigning people on a rostered shift has been rewritten for speed and clearer filtering. Officers see needs matching, leave / overlap / familiarity filters (all default on), Related Info, a lean result grid, and an unmatched-staff credential filter with Find and a two-column picker.

## What changed (full scope)

- Faster staff search (lean `AD_User` + `C_BPartner` query)
- Criteria label **Staff Name**; name search auto-wraps wildcards (no need to type `%`)
- Criteria kept lean: Staff Name, Employee, Agency Staff (Agency Staff is filter-only, not a grid column)
- When opened from a shift: hide approved leave and overlapping roster by default
- **Employees Not On Leave** tick (default on): exclude staff on approved leave overlapping the window; untick to include them
- **Employee Not Rostered at this Time** tick (default on): exclude staff already on any overlapping rostered shift; untick to include them
- **Show Familiar Staff** tick (default on): only staff who worked a rostered shift at this Support Location in the last 12 months (templates excluded); untick to include all
- **Show Matched Staff** tick (default on): Related Rostering Needs apply. Untick to ignore needs and show a two-column credential picker — **Must have all of these credentials** / Find / Selected summary on the left, **Select (AND)** checklist on the right; selected credentials filter with AND; empty selection = full unmatched pool
- Banner: shift context, required needs summary, filter status (including selected credential count)
- Related Info: roster period shifts, leave, unavailability, alerts, credentials
- Contact pick fills Business Partner (callout + save trigger); org sync helpers
- Result grid read-only selection; hides BP Name / Status / Business Partner / Agency Staff columns
- Indexes + AlwaysUpdateable on Employee Search field; perf indexes / join-based Gender & Position

## Impact

- Rostering officers assigning staff on **Shift (Rostered) → Employee**
- Day-to-day: quicker search, fewer unsuitable people in the default list
- Does **not** change Accept Shift Request (separate ticket SAW011)

## How to test

1. Log in as AbilityERP Admin / Admin / Rostering.
2. Open a **Shift (Rostered)** with a real org (not `*`) → **Employee** → staff Search.
3. Confirm four filter ticks on one row under criteria (all default on): **Show Matched Staff**, **Employee Not Rostered at this Time**, **Employees Not On Leave**, **Show Familiar Staff**.
4. Search by name without `%`.
5. Confirm banner shows shift context (not “No shift in context”).
6. Confirm leave / overlapping roster / familiarity / needs filters independently via the ticks.
7. Untick **Show Matched Staff** → confirm two columns (Find / Selected | Select checklist) → type in Find to narrow → select two → summary updates → ReQuery → Clear → re-tick (picker hides).
8. Confirm lean grid (no On Approved Leave / Has Future Shift / BP Name / Status / Business Partner / Agency Staff columns).
9. Pick a contact and confirm BP fills; check Related Info tabs.

## Notes / caveats

- Requires Info Window UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf` already present.
- JAR must be **`1.1.0.2026071517`** and **≥ ~40 KB**. A ~29 KB file with an older version string is a **stale build** (banner only — missing ticks / credential list).
- Install includes Java plugin — iDempiere restart, then log out/in or Cache Reset.
- Do not wipe the full OSGi configuration cache.
