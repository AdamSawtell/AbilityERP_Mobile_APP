# SAW011 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Shift (Rostered) → Response Log  
**Internal ID:** SAW011_accept_shift_request

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Window** | Shift (Rostered) | Unchanged shell — Response Log gains Accept action |
| **Tab** | Response Log | Updated — Accept Shift Request button / toolbar |
| **Tab** | Employee | Updated by process — worker assigned on accept |
| **Process** | Accept Shift Request (`SHIFT_ACCEPT_REQUEST` / `AcceptShiftRequest`) | **New** |
| **Button / column** | Accept Shift Request (`AbERP_AcceptShiftRequest`) | **New** on Response Log |
| **Menu** | *(none new)* | Uses existing Shift (Rostered) menu |

**Admin access:** AbilityERP Admin (and Rostering Officer) have process access so Accept is visible and runnable.

---

## What’s been done

Rostering officers can **Accept Shift Request** from a worker’s **Yes – Request Shift** response on the Response Log. That assigns the worker onto the shift **Employee** tab, marks the response reviewed, and publishes the shift.

## What changed

- New **Accept Shift Request** action on **Shift (Rostered) → Response Log**
- Only for **REQ** (request) responses that are not already reviewed or superseded
- Hidden when the shift already has an employee assigned
- Assigns the requesting worker on the Employee tab
- Marks the response log reviewed and updates shift published status / availability flags as designed

## Impact

- Rostering officers allocating requested shifts without manual re-keying of the employee
- Workers still request via the mobile/app response path; acceptance is WebUI

## How to test

1. Log in as AbilityERP Admin or Rostering Officer.
2. Open a **Shift (Rostered)** with a pending **REQ** on **Response Log**.
3. Select the REQ row → **Accept Shift Request**.
4. Confirm the worker appears on the **Employee** tab.
5. Confirm the response is marked reviewed and the button no longer shows for that row / already-staffed shifts.
6. Confirm declined / reviewed rows do not show Accept.

## Notes / caveats

- Install includes a Java plugin — restart iDempiere, then log out/in.
- Published status uses a configured Shift Status on the build; confirm “Published” resolves correctly on the target client.
- Do not clear the full OSGi cache as a “fix” (can break other AbERP plugins).
