# SAW007 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere — Activity tabs on booking / agreement windows  
**Internal ID:** SAW007_activity_tab_integration

## What’s been done

**Activity** tabs have been registered on key operational windows so users can log contact activities in context (aligned with Enquiry Activity patterns). User/contact field behaviour is corrected so activities are not forced to the logged-in user where Business Partner + contact should apply.

## What changed

- Activity tab available on Booking Generator / Service Booking / Service Agreement (Project) as installed for the client
- Link columns / registration so activities attach to the correct parent
- User/contact wiring fix for Contact Activity where required
- Optional hide of redundant user field where BP contact is the right capture

## Impact

- Staff who log activities from those windows
- Improves consistency of activity capture across booking and agreement work
- **AbilityERP Admin** can open the windows/tabs and create activities

## How to test

1. Log in as AbilityERP Admin.
2. Open each installed parent window → **Activity** tab → New.
3. Confirm activity types are available and save succeeds.
4. Confirm contact/user fields behave as expected (BP contact, not forced to yourself unless that is the design).
5. Confirm Admin role can see the tab (log out/in if access was just granted).

## Notes / caveats

- Other-build installs must use the **portable** registration scripts (not seed-only window IDs).
- Prerequisite: Contact Activity / Enquiry Activity patterns must already exist on the client.
