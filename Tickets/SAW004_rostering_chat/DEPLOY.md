# SAW004 — Deploy to another build

**Ticket:** `SAW004_rostering_chat` · **Kind:** both · **JAR:** Yes (SQL alone is incomplete)

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.rostering.chat
chmod +x build.sh deploy.sh
sudo ./deploy.sh
# includes verify-install.sql; restarts idempiere — then logout/in
```

**Primary plugin doc:** [`idempiere-plugins/com.aberp.rostering.chat/DEPLOY.md`](../../idempiere-plugins/com.aberp.rostering.chat/DEPLOY.md)  
Remote helper (if used): `scripts/deploy-rostering-chat-plugin.sh`

## Package

`idempiere-plugins/com.aberp.rostering.chat/`

## Ordered SQL (deploy.sh)

1. `sql/install-rostering-chat.sql`  
2. `21-send-button-awaiting-order.sql` … through `33-rename-processes.sql` (see plugin `DEPLOY.md`)  
3. `sql/verify-install.sql`  

Do **not** re-run historical `04`–`20` unless debugging.

## Restart / cache

- **Yes** restart idempiere  
- **Yes** logout/in (AD cache)

## WebUI smoke

1. Open **Rostering Chat**; default inbox ≈ Response required.  
2. Grid shows activity / assigned / worker / last message.  
3. **Send Chat** / **Close Chat** on a thread.  
4. OSGi: `com.aberp.rostering.chat` ACTIVE; processes `AbERP_RosteringChat_Send` / `AbERP_RosteringChat_Close`.

## App dependency (Kind both)

If this release also changed chat sync/UX, deploy app/API as well:

- `web/src/app/(app)/tasks/`, `web/src/components/TaskChat.tsx`
- `api` request/chat routes

## Blockers / notes

- **Chat Assigned** SQL may hardcode Rostering Officer `AD_Role_ID = 1000012` — confirm on target and patch if different.
- Needs roles **Rostering Officer**, **AbilityERP Admin**; request type **Rostering Chat**.
- SAW006 was the same project (Requests clone) — pack only as **SAW004**.

## Packs

- Prefer applying from repo via `deploy.sh` until `AbilityERP-*-SAW004_rostering_chat-*` packs exist.
