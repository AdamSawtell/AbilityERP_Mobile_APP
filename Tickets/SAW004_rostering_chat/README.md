# SAW004 — Rostering Chat

| | |
|--|--|
| **Status** | done (ready to pack to other builds) |
| **Kind** | both |
| **GitHub** | [#4](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/4) (also [#6](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/6) merged here) |
| **Slug** | `SAW004_rostering_chat` |

## Deploy (other builds)

**→ [`DEPLOY.md`](DEPLOY.md)** (ticket) and plugin [`idempiere-plugins/com.aberp.rostering.chat/DEPLOY.md`](../../idempiere-plugins/com.aberp.rostering.chat/DEPLOY.md).

## Goal

Rostering officers get a WebUI inbox for worker chat on `R_Request` / `R_RequestUpdate`. The window is a trimmed **clone of Requests**, filtered to request type **Rostering Chat**, with reply/close aligned to the mobile Chat (`/tasks`) path.

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.rostering.chat/`
- Install AD: `…/sql/install-rostering-chat.sql` + patches `21`…`33` (order in `DEPLOY.md` / `deploy.sh`)
- Verify: `…/sql/verify-install.sql`
- Java: `SendRosteringReply`, `CloseRosteringChat`, `RosteringChatValidator`, `RosteringChatTabPanel`
- App: `web/src/app/(app)/tasks/`, `web/src/components/TaskChat.tsx`, `api` request/chat routes

## Window / menu

| Object | Name |
|--------|------|
| Window | **Rostering Chat** |
| Tabs | **Chat** (`R_Request`), **Updates** (`R_RequestUpdate`) |
| Request type | **Rostering Chat** |
| Menu | **Rostering Chat** |
| Processes | `AbERP_RosteringChat_Send`, `AbERP_RosteringChat_Close` |

## Known portability caveat

Chat Assigned logic hardcodes **Rostering Officer** as `AD_Role_ID = 1000012` on the reference tenant. `verify-install.sql` warns if the target role ID differs — fix before production use.

## Dependencies (app)

App chat inbox/sync must stay compatible with WebUI reply/close/status. Kind **both** when shipping ERP + app in one release.

## Packs

- Folder pack: `idempiere-plugins/com.aberp.rostering.chat/` (jar + SQL via `deploy.sh`)
- Naming: `AbilityERP-*-SAW004_rostering_chat-*`
