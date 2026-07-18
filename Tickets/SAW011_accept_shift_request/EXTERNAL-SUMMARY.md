# SAW011 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Shift (Rostered) → Response Log  
**Internal ID:** SAW011_accept_shift_request

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Window** | Shift (Rostered) | Response Log gains Accept + Find and Fill |
| **Tab** | Response Log | **Accept Shift Request** and **Find and Fill** buttons |
| **Tab** | Employee | Filled by either action |
| **Process** | Accept Shift Request | Assign REQ worker without opening Info |
| **Process** | Find and Fill | Opens Staff Rostering Info; OK fills vacant slot |
| **Info Window** | Employee (User) / Agency Staff Rostering Info | Existing Find & Fill (used from Response Log) |
| **Menu** | *(none new)* | Existing Shift (Rostered) menu |

## Access

| Access | Name | Search key |
|--------|------|------------|
| Process | Accept Shift Request | `SHIFT_ACCEPT_REQUEST` |
| Process | Find and Fill | `AbERP_ResponseLog_FindFill` |
| Info Window | Employee (User) / Agency Staff Rostering Info | — |
| Window | Shift (Rostered) | — |

Granted to AbilityERP Admin, Admin, and Rostering / Rostering TL / Rostering Officer when those roles exist.

---

## What’s been done

Rostering officers can handle Response Log requests two ways:

1. **Accept Shift Request** — quick assign for a **Yes – Request Shift** row  
2. **Find and Fill** — review that worker against the shift (leave / overlap / familiar / matched) in the usual Find & Fill screen, then OK to fill a vacant Employee line  

Both mark the response reviewed and publish when applicable. Buttons hide when Reviewed is already set.

## How to test

1. Log in as **Admin** (or AbilityERP Admin / Rostering).  
2. Open a **Shift (Rostered)** with a vacant Employee line and an unreviewed Response Log row.  
3. **Accept:** on a REQ row, click **Accept Shift Request** → confirm Employee + Reviewed.  
4. **Find and Fill:** on another unreviewed row, click **Find and Fill** → confirm Info opens with the worker → OK → confirm Employee + Reviewed.  
5. Confirm Reviewed rows no longer show either button.

## Notes / caveats

- Install includes Java plugins — restart iDempiere, then log out/in.  
- Find and Fill requires the Staff Rostering Info (Find & Fill) already on the build.  
- Do not clear the full OSGi cache as a “fix”.
