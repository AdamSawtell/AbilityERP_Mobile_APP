# SAW007 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Activity tabs on booking / agreement windows  
**Internal ID:** SAW007_activity_tab_integration

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Window** | Booking Generator | Updated — **Activity** tab registered |
| **Window** | Service Booking | Updated — **Activity** tab registered |
| **Window** | Service Agreement (Project) | Updated — **Activity** tab registered |
| **Tab** | Activity (`C_ContactActivity`) | **New** on the windows above (clone of Enquiry Activity pattern) |
| **List** | Contact Activity Type (`EM` / `ME` / `PC` / `CN` / `TA`) | Window grants for Email, Meeting, Phone call, Case Note, Task |
| **Table / columns** | Contact Activity link columns | Added/updated as required for parent link |
| **Process** | *(none new)* | — |
| **Menu** | *(none new)* | Uses existing parent window menus |

**Admin access:** AbilityERP Admin can open the parent windows and use the Activity tabs.

---

## What’s been done

**Activity** tabs have been registered on key operational windows so users can log contact activities in context (aligned with Enquiry Activity patterns). User/contact field behaviour is corrected so activities are not forced to the logged-in user where Business Partner + contact should apply.

On each of those Activity tabs, the Activity Type list includes:

| Business name | List value |
|---------------|------------|
| Email | EM |
| Meeting | ME |
| Phone call | PC |
| Note (Case Note) | CN |
| Task | TA |

## What changed

- Activity tab available on Booking Generator / Service Booking / Service Agreement (Project) as installed for the client
- Link columns / registration so activities attach to the correct parent
- User/contact wiring fix for Contact Activity where required
- Optional hide of redundant user field where BP contact is the right capture
- Activity Type window grants for Email, Meeting, Phone call, Case Note, Task on all three windows

## Impact

- Staff who log activities from those windows
- Improves consistency of activity capture across booking and agreement work

## How to test

1. Log in as AbilityERP Admin (or Admin on HCO).
2. Open each installed parent window → **Activity** tab → New.
3. Confirm Activity Type offers **Email, Meeting, Phone call, Case Note, Task** and save succeeds.
4. Confirm contact/user fields behave as expected (BP contact, not forced to yourself unless that is the design).
5. Confirm Admin role can see the tab (log out/in if access was just granted).

## Notes / caveats

- Other-build installs must use the **portable** registration scripts (not seed-only window IDs).
- Prerequisite: Contact Activity / Enquiry Activity patterns must already exist on the client.
- **Note** in the requirement is the existing **Case Note** (`CN`) list entry.
