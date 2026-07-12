# SAW004 — External ticket update (copy/paste)

**Status:** Ready for client install  
**Area:** iDempiere WebUI — Rostering Chat (+ mobile chat compatibility)  
**Internal ID:** SAW004_rostering_chat  
**(Note: formerly also tracked as “Requests window clone” / SAW006 — same deliverable.)**

## Windows / processes / objects affected

| Type | Name | Change |
|------|------|--------|
| **Window** | Rostering Chat | **New** — trimmed Requests-style window |
| **Tab** | Chat (`R_Request`) | **New** — header / inbox |
| **Tab** | Updates (`R_RequestUpdate`) | **New** — message history |
| **Request type** | Rostering Chat | **New** / ensured — filters inbox |
| **Menu** | Rostering Chat | **New** — menu entry near Shift Rostered |
| **Process** | Send Chat (`AbERP_RosteringChat_Send`) | **New** — officer reply |
| **Process** | Close Chat (`AbERP_RosteringChat_Close`) | **New** — close thread |
| **Buttons** | Send Chat / Close Chat | **New** — on Chat tab |

**Admin access:** AbilityERP Admin has window + process access for Rostering Chat, Send, and Close.

---

## What’s been done

A dedicated **Rostering Chat** window gives rostering officers an inbox for worker chat threads (same request/update data the mobile app uses). Officers can reply and close chats from the WebUI.

## What changed

- New window **Rostering Chat** (based on a trimmed Requests layout, filtered to Rostering Chat)
- Tabs for the chat header and **Updates** history
- **Send Chat** / **Close Chat** actions for officers
- Inbox defaults aimed at threads that need a response
- Grid shows last activity, assigned officer, worker, last message (as configured)
- Mobile/app chat remains the worker side; WebUI is the officer side

## Impact

- Rostering officers and AbilityERP Admin using WebUI chat
- Workers continue to use the mobile app chat
- Does not replace Shift Offer / Accept Shift Request flows

## How to test

1. Log in as AbilityERP Admin or Rostering Officer.
2. Open **Rostering Chat** from the menu.
3. Confirm the inbox lists relevant threads (e.g. response required).
4. Open a thread, send a reply, confirm it appears in Updates and on the worker side (if testing both).
5. Close a chat and confirm status/behaviour matches your process.
6. Confirm Admin can see the window and buttons after log out/in (or Role Access Update).

## Notes / caveats

- Install includes a Java plugin — restart iDempiere, then log out/in.
- Some builds hardcode Rostering Officer role id in “Chat Assigned” SQL — confirm that role id on the target client if assignments look wrong.
- App deploy is only needed if this release also changed mobile chat sync/UX.
