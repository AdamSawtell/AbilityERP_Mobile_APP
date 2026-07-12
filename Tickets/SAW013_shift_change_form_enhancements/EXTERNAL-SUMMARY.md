# SAW013 — External ticket update (copy/paste)

**Status:** Ready for client install (staged on HCO Test)  
**Area:** iDempiere — HCO Forms and Approvals  
**Internal ID:** SAW013_shift_change_form_enhancements

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Window** | HCO Forms and Approvals | Updated — auto Status + Request Submitted |
| **Tab** | HCO Forms and Approvals (`AbERP_ShiftChange`) | Status read-only from linked Request; new Request Submitted field |
| **Tab** | Requests (`R_Request`) | Unchanged (still linked child) |
| **Process** | Create Request From Template | Button hidden once a request exists; DB also blocks a second active request |
| **Form / Info** | *(none)* | — |

**Admin access:** AbilityERP Admin (and Admin) can open **HCO Forms and Approvals** as before. No new menu item.

---

## What’s been done

Status on the Shift Change form now follows the linked Request automatically. Staff can see whether a request was already submitted, and cannot accidentally create another request for the same form.

## What changed

- **Status** is read-only and stays in sync with the linked Request (database sync when the Request changes).
- New field **Request Submitted** (Yes/No).
- **Create Request From Template** only appears when no request exists yet.
- The database also prevents a second active Request for the same form.

## Impact

- Rostering / service staff who use **HCO Forms and Approvals**
- Request action staff no longer need to keep Status in sync on the form manually

## How to test

1. Log in as Admin / AbilityERP Admin.
2. Open **HCO Forms and Approvals**.
3. Open a form that already has a row on the **Requests** tab → Status matches; Request Submitted = Yes; Create button not shown.
4. Open (or create) a form with no request → Request Submitted = No; use **Create Request From Template** once → after refresh, Submitted = Yes and Create is gone.
5. Confirm existing Requests / Updates tabs still work.

## Notes / caveats

- After creating a request, refresh or reopen the record if Status / Submitted do not update immediately in the open window.
- Older forms that already have more than one request are not cleaned up automatically; new duplicates are blocked going forward.
- After install: Cache Reset or log out/in.
