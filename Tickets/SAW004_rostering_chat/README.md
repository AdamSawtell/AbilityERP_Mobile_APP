# SAW004 — Rostering Chat

| | |
|--|--|
| **Status** | done |
| **Kind** | both |
| **GitHub** | [#4](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/4) (also [#6](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/6) merged here) |
| **Slug** | `SAW004_rostering_chat` |

## Goal

Rostering officers get a WebUI inbox for worker chat on `R_Request` / `R_RequestUpdate`. The window is a trimmed **clone of Requests**, filtered to request type **Rostering Chat**, with reply/close aligned to the mobile Chat (`/tasks`) path.

(Formerly tracked separately as SAW006 “Requests window clone” — same deliverable.)

## Source of truth

- Plugin: `idempiere-plugins/com.aberp.rostering.chat/`
- Install AD: `…/sql/install-rostering-chat.sql` (+ follow-on `04-`…`31-*.sql`)
- Java: `SendRosteringReply`, `CloseRosteringChat`, `RosteringChatValidator`, `RosteringChatTabPanel`
- App: `web/src/app/(app)/tasks/`, `web/src/components/TaskChat.tsx`, `web/src/app/api/requests/chat/`, `api/src/routes/requests.ts`, `api/src/db/queries/requests.ts`

## Window / menu

| Object | Name |
|--------|------|
| Window | **Rostering Chat** |
| Tabs | **Chat** (`R_Request`), **Updates** (`R_RequestUpdate`) |
| Request type | **Rostering Chat** |
| Menu | **Rostering Chat** (near Shift Rostered) |
| Processes | `ROSTERING_CHAT_REPLY`, `ROSTERING_CHAT_CLOSE` |

## Dependencies (app)

App chat inbox/sync must stay compatible with WebUI reply/close/status. Kind **both** when shipping ERP + app in one release.

## Packs

- `AbilityERP-*-SAW004_rostering_chat-*`
