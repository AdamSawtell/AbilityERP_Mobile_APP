# Rostering Chat — iDempiere Plugin

WebUI window for rostering officers to manage mobile app chat threads.

## What it does

| Feature | Detail |
|---------|--------|
| **Window** | **Rostering Chat** — filtered `R_Request` inbox |
| **Filter** | `R_RequestType` = **Rostering Chat** only |
| **History** | **Updates** tab — read-only `R_RequestUpdate` message list |
| **Reply** | Editable **Last Result** field — type your message on the header |
| **Send to Worker** | Button — creates `R_RequestUpdate`, sets worker as User/Contact, clears Role, saves |
| **Close Chat** | Button — sets status to Closed; mobile opens a fresh thread next time |

Worker recipient is resolved from User/Contact on the request (the mobile worker who opened the thread).

## Build (on iDempiere server)

```bash
cd idempiere-plugins/com.aberp.rostering.chat
chmod +x build.sh deploy.sh
./build.sh
```

## Deploy

```bash
./deploy.sh
```

Or from your dev machine:

```bash
bash scripts/deploy-rostering-chat-plugin.sh
```

After deploy: **log out and log back in** on the WebUI.

## Manual test

1. Log in as **Rostering Officer** or **AbilityERP Admin**.
2. Open **Rostering Chat** (menu near Shift (Rostered)).
3. Confirm only mobile chat threads appear.
4. Open a thread → **Updates** tab shows message history.
5. Type a reply in **Reply (Last Result)** → click **Send to Worker** → confirm update in Updates and on mobile Tasks.
6. Click **Close Chat** → confirm status becomes Closed; mobile gets a new thread on next message.

## SQL

- `sql/install-rostering-chat.sql` — idempotent AD install (window, tabs, fields, processes, access, menu)

## Processes

| Value | Class |
|-------|-------|
| `AbERP_RosteringChat_Send` | `com.aberp.rostering.chat.process.SendRosteringReply` |
| `AbERP_RosteringChat_Close` | `com.aberp.rostering.chat.process.CloseRosteringChat` |

## Role access

- AbilityERP Admin (`1000004`)
- Rostering Officer (`1000012`)
- System Administrator (`0`)
