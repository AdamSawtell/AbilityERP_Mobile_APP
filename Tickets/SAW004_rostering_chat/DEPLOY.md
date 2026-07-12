# SAW004 — Deploy to another build (agent)

**Ticket / slug:** `SAW004_rostering_chat`  
**Kind:** both · **JAR:** Yes (SQL alone incomplete) · **Status:** done

**Also read:** `idempiere-plugins/com.aberp.rostering.chat/DEPLOY.md` (authoritative SQL order + verify).

## Required host access

- SSH · `psql` · WebUI Admin · OSGi / restart  
- Roles by **name**: `AbilityERP Admin`, `Rostering Officer`  
- Request type **Rostering Chat** (created by install if missing)

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.rostering.chat
chmod +x build.sh deploy.sh
sudo ./deploy.sh
# jar + SQL + verify-install.sql + restart + wait WebUI 200 → logout/in
```

Remote helper (optional): `bash scripts/deploy-rostering-chat-plugin.sh`

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.rostering.chat/` |
| Symbolic name | `com.aberp.rostering.chat` |
| Version | see MANIFEST / `deploy.sh` (e.g. `7.1.0.202607121200`) |

## Ordered SQL (`deploy.sh` — exact)

1. `sql/install-rostering-chat.sql`  
2. `sql/21-send-button-awaiting-order.sql`  
3. `sql/24-silent-send-close.sql`  
4. `sql/25-silent-reply-default.sql`  
5. `sql/26-officer-create-chat.sql`  
6. `sql/27-chat-assigned-refresh.sql`  
7. `sql/28-live-header-refresh.sql`  
8. `sql/29-close-zombie-chats.sql`  
9. `sql/30-send-chat-layout.sql`  
10. `sql/31-inbox-default-query.sql`  
11. `sql/32-shared-grid-view.sql`  
12. `sql/33-rename-processes.sql`  
13. `sql/verify-install.sql`  

Do **not** re-run historical `04`–`20` unless debugging. There is **no** `22`/`23` in the current chain.

## AbilityERP Admin access

`install-rostering-chat.sql` grants window + process access to **AbilityERP Admin** and **Rostering Officer** (by name). Confirm after deploy; Role Access Update / logout-in. Smoke **as Admin**.

## Portability risks (stop before go-live if mismatched)

```sql
SET search_path TO adempiere, public;
SELECT ad_role_id, name FROM ad_role WHERE name = 'Rostering Officer';
```

Chat Assigned logic still hardcodes `AD_Role_ID = 1000012` in `21` / `27` / `30` (and some historical scripts). If Rostering Officer ≠ `1000012` on target, **patch those scripts** (or align role id) before production use. `verify-install.sql` warns.

## Kind both — app

If this release also changed mobile chat: deploy app/API (`web` tasks / `TaskChat`, `api` request/chat) and smoke worker ↔ officer sync. ERP-only re-ship: skip app if unchanged.

## WebUI smoke

Open **Rostering Chat** → inbox → Send Chat / Close Chat → processes `AbERP_RosteringChat_Send` / `AbERP_RosteringChat_Close` · bundle ACTIVE.

## Packs

Prefer repo `deploy.sh`. Create `AbilityERP-*-SAW004_rostering_chat-*` when shipping without git. No rollback SQL yet — document residual if packing.

## External ticket text

`Tickets/SAW004_rostering_chat/EXTERNAL-SUMMARY.md`
