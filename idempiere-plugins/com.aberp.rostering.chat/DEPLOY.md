# Rostering Chat — deploy pack (agent handoff)

Install this plugin on a target iDempiere build. Source of truth: this folder.

Ticket home: `Tickets/SAW004_rostering_chat/`

## What ships

| Piece | Path |
|-------|------|
| OSGi bundle | `com.aberp.rostering.chat` (built by `build.sh`) |
| AD + DB install | `sql/install-rostering-chat.sql` then numbered patches below |
| Verify | `sql/verify-install.sql` |

**Not a 2Pack-only deliverable** — Java classes (Send/Close + live tab panel) require the jar. SQL alone is incomplete.

## Prerequisites (resolve by **name**, not ID)

On the target tenant these must exist (or be created / mapped before deploy):

| Object | Expected name | Notes |
|--------|---------------|--------|
| Client | `AbilityERP` (preferred) | UserQuery client falls back to first non-System client |
| Role | `Rostering Officer` | Queue role for “Response required”; also gets window/process access |
| Role | `AbilityERP Admin` | Window + process access |
| Request type | `Rostering Chat` | Created by install if missing |
| Status Closed | usually `R_Status_ID` 102 / name Closed | Close process / triggers assume Closed semantics |

**Hardcoded role ID still used in Chat Assigned logic:** `AD_Role_ID = 1000012` (= Rostering Officer on the reference build).  
Before go-live on another build, confirm:

```sql
SET search_path TO adempiere, public;
SELECT ad_role_id, name FROM ad_role WHERE name = 'Rostering Officer';
```

If the ID is not `1000012`, stop and patch triggers/SQL that reference `1000012` (see `sql/21-*.sql`, `27-*.sql`, `30-*.sql`) to that role’s ID — or align the target so Rostering Officer is `1000012`.

## One-command deploy (on the iDempiere host)

```bash
cd /path/to/repo/idempiere-plugins/com.aberp.rostering.chat
chmod +x build.sh deploy.sh
sudo ./deploy.sh
```

`deploy.sh` will:

1. Build `com.aberp.rostering.chat_<version>.jar` against `$IDEMPIERE_HOME` (default `/opt/idempiere-server`)
2. Install jar into `plugins/` + `customization-jar/` and register `bundles.info`
3. Apply SQL in order (below)
4. `systemctl restart idempiere` and wait for WebUI HTTP 200
5. Start the OSGi bundle if Chuboe utils are present

From a workstation (reference pattern):

```bash
# set EC2_HOST / SSH_KEY / REMOTE_DIR as needed
bash scripts/deploy-rostering-chat-plugin.sh
```

## SQL apply order (idempotent)

Already encoded in `deploy.sh`. Do **not** skip later patches — `install-rostering-chat.sql` alone is not the finished UX.

1. `install-rostering-chat.sql` — window, tabs, columns, processes, menu, access  
2. `21-send-button-awaiting-order.sql`  
3. `24-silent-send-close.sql`  
4. `25-silent-reply-default.sql`  
5. `26-officer-create-chat.sql`  
6. `27-chat-assigned-refresh.sql`  
7. `28-live-header-refresh.sql`  
8. `29-close-zombie-chats.sql`  
9. `30-send-chat-layout.sql`  
10. `31-inbox-default-query.sql`  
11. `32-shared-grid-view.sql`  
12. `33-rename-processes.sql`  

Older `04`–`20` scripts are historical; do not re-run unless debugging a broken intermediate state.

### Safe psql pattern

Each SQL file starts with `SET search_path TO adempiere, public;` (or equivalent). Apply as:

```bash
sudo cp sql/FOO.sql /tmp/FOO.sql
sudo chown postgres:postgres /tmp/FOO.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/FOO.sql
```

Do **not** pass `-c "SET search_path …"` before `-f` in the same `psql` invocation (breaks on some hosts).

## Processes to grant on new roles

| Search key (`AD_Process.Value`) | Display name | Class |
|---------------------------------|--------------|--------|
| `AbERP_RosteringChat_Send` | Send Chat | `com.aberp.rostering.chat.process.SendRosteringReply` |
| `AbERP_RosteringChat_Close` | Close Chat | `com.aberp.rostering.chat.process.CloseRosteringChat` |

Also grant **window** access: **Rostering Chat**.

These are the only custom processes for this window.

## Post-deploy verify

```bash
sudo cp sql/verify-install.sql /tmp/verify-install.sql
sudo chown postgres:postgres /tmp/verify-install.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/verify-install.sql
```

Expect:

- Window **Rostering Chat** active; tabs **Chat** + **Updates**
- Processes `AbERP_RosteringChat_Send` / `AbERP_RosteringChat_Close`
- Process + window access for Rostering Officer + AbilityERP Admin
- Chat tab `whereclause` contains the target’s Rostering Chat `R_RequestType_ID`
- Grid fields (IsDisplayedGrid=Y): Last Activity, Chat Assigned, Worker, Last Message
- Bundle `com.aberp.rostering.chat` **ACTIVE** in OSGi

### WebUI smoke

1. Log out / log in (AD cache).
2. Open **Rostering Chat**.
3. Inbox should default to **Response required** (`[n/n]` filtered — not all Awaiting worker rows).
4. Toggle **Grid**: columns Last Activity | Chat Assigned | Worker | Last Message.
5. Form: Reply + **Send Chat** / **Close Chat** (buttons start near column 2).
6. Optional: Lookup → **Awaiting worker** / **Closed**.

## App / API dependency (Kind: both)

WebUI alone is not enough for workers. Target environment also needs a compatible mobile/API stack:

- App: `web` Tasks chat
- API: `api` request/chat routes and `requests.ts` subject default **Rostering Chat**

Ship ERP plugin + app/API when the target build serves workers.

## Version

Current bundle version is set in `META-INF/MANIFEST.MF`, `build.sh`, and `deploy.sh` (keep them in sync when bumping).
