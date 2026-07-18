# SAW011 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Shift (Rostered) → Response Log  
**Internal ID:** SAW011_accept_shift_request

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Window** | Shift (Rostered) | Unchanged shell — Response Log gains Accept action |
| **Tab** | Response Log | Updated — Accept via detail toolbar Process on selected row |
| **Tab** | Employee | Updated by process — worker assigned on accept |
| **Process** | Accept Shift Request (`SHIFT_ACCEPT_REQUEST` / `AcceptShiftRequest`) | **New** |
| **Button / column** | Accept Shift Request (`AbERP_AcceptShiftRequest`) | **New** on Response Log |
| **Menu** | *(none new)* | Uses existing Shift (Rostered) menu |

**Admin access:**

| Access | Name | Search key |
|--------|------|------------|
| Process | Accept Shift Request | `SHIFT_ACCEPT_REQUEST` |

Granted to AbilityERP Admin, Admin, and Rostering / Rostering TL / Rostering Officer when those roles exist.

---

## What’s been done

Rostering officers / Admin can **Accept Shift Request** from a worker’s **Yes – Request Shift** row on the Response Log. That assigns the worker onto the shift **Employee** tab, marks the response reviewed, and publishes the shift.

## What the function does (step by step)

1. Open **Shift (Rostered)** → **Response Log**
2. Select a **Yes – Request Shift** row that is not reviewed / superseded
3. On that response row’s toolbar, open **Process** → **Accept Shift Request**
4. System copies that response’s user onto the **Employee** tab (`AbERP_User_Contact_ID` on shift staff)
5. Marks the response **Reviewed**
6. Clears “showing as available” and sets shift status to **Published**
7. Accept is hidden for reviewed / superseded rows; process also blocks if the shift already has an employee

## How to test

1. Log in as **Admin** (or AbilityERP Admin / Rostering).
2. Open a **Shift (Rostered)** with a pending **Yes – Request Shift** on **Response Log**.
3. Select that row → toolbar **Process** → **Accept Shift Request**.
4. Confirm the worker appears on the **Employee** tab.
5. Confirm the response is marked reviewed and Accept no longer shows for that row.
6. Confirm declined / reviewed / already-staffed rows cannot be accepted.

## Notes / caveats

- Install includes a Java plugin — restart iDempiere, then log out/in.
- Published status uses Shift Status → **Published** by name (portable across clients).
- Do not clear the full OSGi cache as a “fix” (can break other AbERP plugins).
