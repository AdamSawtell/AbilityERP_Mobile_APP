# SAW001 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Notification / Invoice Info  
**Internal ID:** SAW001_paid_filter_invoice_send_info

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Info Window** | Notification SR Invoice Send Info | Updated — Paid search criteria + Paid result column |
| **Menu** | Notification SR Invoice Send Info (Action = Info) | Added/updated — direct open for testing |
| **Process** | *(none new)* | — |
| **Window / Tab** | *(none)* | — |
| **Form** | *(none)* | Create From still uses existing Logilite form if present |

**Admin access:** AbilityERP Admin can open the Info Window (and menu) and use the Paid filter.

---

## What’s been done

A **Paid** search option has been added to the **Notification SR Invoice Send Info** window so staff can filter invoices by payment status when selecting invoices for notification runs.

## What changed

- New search field: **Paid** — Yes / No / leave blank (no payment filter)
- New result column showing whether each invoice is paid
- Uses the existing invoice **Is Paid** flag (no change to how payments are recorded)
- Optional menu entry so the Info Window can be opened directly for testing

## Impact

- Rostering / finance / notification users who use **Notification SR Invoice Send Info** or Create From on notification runs
- Does **not** change notification sending logic itself — only which invoices appear in the search results

## How to test

1. Log in as AbilityERP Admin (or a role with access to the Info Window).
2. Open **Notification SR Invoice Send Info** (menu or Create From on the notification run, if available).
3. Set date / document criteria as usual.
4. Set **Paid = Yes** → only paid invoices; **Paid = No** → only unpaid; **blank** → both.
5. Confirm selected rows still work with the notification run flow.

## Notes / caveats

- If Create From fails with a missing Logilite form class, open the Info Window from the menu instead (known pre-existing limitation on some builds).
- After install: Cache Reset or log out/in.
