# Rostering Chat — iDempiere Plugin

WebUI window for rostering officers to manage mobile app chat threads.

**Deploying to another build?** Start with [`DEPLOY.md`](./DEPLOY.md) (agent handoff).

## What it does

| Feature | Detail |
|---------|--------|
| **Window** | **Rostering Chat** — filtered `R_Request` inbox |
| **Filter** | Request type **Rostering Chat** only; default open = **Response required** |
| **History** | **Updates** tab — read-only `R_RequestUpdate` message list |
| **Reply** | **Reply** field + **Send Chat** / **Close Chat** |
| **Grid** | Shared columns via `AD_Field` SeqNoGrid (Last Activity, Chat Assigned, Worker, Last Message) |

## Build / deploy (on iDempiere server)

```bash
cd idempiere-plugins/com.aberp.rostering.chat
chmod +x build.sh deploy.sh
sudo ./deploy.sh
```

From a workstation against a remote host:

```bash
bash scripts/deploy-rostering-chat-plugin.sh
```

After deploy: **log out and log back in** on the WebUI.

## Manual test

1. Log in as **Rostering Officer** or **AbilityERP Admin**.
2. Open **Rostering Chat**.
3. Confirm inbox shows **Response required** only (Lookup Lookup for other states).
4. Toggle Grid — columns: Last Activity, Chat Assigned, Worker, Last Message.
5. Type Reply → **Send Chat** → message appears in Updates / mobile Tasks.
6. **Close Chat** → Closed; worker can start a new conversation.

## Processes (role access)

| Value | Name | Class |
|-------|------|--------|
| `AbERP_RosteringChat_Send` | Send Chat | `com.aberp.rostering.chat.process.SendRosteringReply` |
| `AbERP_RosteringChat_Close` | Close Chat | `com.aberp.rostering.chat.process.CloseRosteringChat` |

Also grant window **Rostering Chat**.

## Role access (default install)

- AbilityERP Admin
- Rostering Officer
- System Administrator
