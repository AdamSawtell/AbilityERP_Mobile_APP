# SAW033 — Deploy HCO theme plugin

**Ticket / slug:** `SAW033_hco_theme_plugin`  
**Kind:** idempiere · **JAR:** yes · **SQL:** sysconfig + optional toolbar Restrict  
**Status:** staging tested on `3.27.122.147`

## Required host access

- SSH to iDempiere host
- Ability to stop/start `idempiere` service
- `psql` for `ZK_THEME` sysconfig
- WebUI admin login

## Staging host (validated 2026-07-23)

| | |
|--|--|
| Host | `3.27.122.147` (`ip-172-31-3-32`) |
| SSH | `ubuntu@3.27.122.147` — key `C:\Users\sawte\Documents\SSH Keys\HCO_Prod_KP.pem` |
| iDempiere | `/opt/idempiere-server` · 7.1 · ZK 8.6 |
| WebUI | `http://3.27.122.147/webui/` |
| Theme key | `hco` |

## Install (staging script)

From repo copy on host (or sync `idempiere-plugins/org.hco.ui.theme/`):

```bash
cd /opt/AbilityERP/idempiere-plugins/org.hco.ui.theme
# ensure LF line endings on *.sh
sed -i 's/\r$//' build.sh deploy-hco-staging.sh
bash deploy-hco-staging.sh
```

What the script does:

1. `build.sh` — extract `theme/default` from `org.adempiere.ui.zk`, rename to `theme/hco`, apply HCO overlay, package fragment JAR (`MANIFEST` forced LF-only).
2. Stop iDempiere.
3. Backup `org.adempiere.ui.zk_*.jar` → `*.pre-hco.bak` (once).
4. Inject `theme/hco` into `org.adempiere.ui.zk` (required on this Jetty 9.4 host — war-fragment resource serving did not expose `/theme/hco/*`).
5. Install fragment JAR to `plugins/` + `bundles.info`.
6. Set sysconfig: `ZK_THEME=hco`, `ZK_LOGIN_LEFTPANEL_SHOWN=Y`, clear `ZK_LOGO_LARGE` / `ZK_LOGO_SMALL`.
7. Start iDempiere and wait for WebUI 200.

### Optional — hide role-unavailable toolbar buttons (Support Worker)

Do **not** CSS-hide grey toolbar icons (many are state, not role). Use Restrict:

```bash
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 \
  -f /opt/AbilityERP/idempiere-plugins/org.hco.ui.theme/sql/02-toolbar-restrict-window-level.sql
# Cache Reset or restart iDempiere so MToolBarButtonRestrict cache reloads
```

Repo path: `idempiere-plugins/org.hco.ui.theme/sql/02-toolbar-restrict-window-level.sql`

## Rollback

```bash
sudo /etc/init.d/idempiere stop
sudo cp -a /opt/idempiere-server/plugins/org.adempiere.ui.zk_7.1.0.202503110454.jar.pre-hco.bak \
  /opt/idempiere-server/plugins/org.adempiere.ui.zk_7.1.0.202503110454.jar
sudo -u postgres psql -d idempiere -c "SET search_path TO adempiere; UPDATE ad_sysconfig SET value='default' WHERE name='ZK_THEME';"
sudo /etc/init.d/idempiere start
```

## Smoke (passed on staging)

- [x] Login page HCO logo + tagline + teal accents
- [x] `ZK_THEME=hco` stylesheet `/webui/theme/hco/css/theme.css.dsp` (~80KB with Poppins / `#25cad2`)
- [x] Desktop header `#151515`, body `#eaeaea`, Poppins
- [x] Active tabs `3px solid #25cad2` underline
- [x] Employee window toolbar tiles `#25cad2`, radius `8px`, navy text
- [x] Grid headers `#00a2bd`
- [x] Record nav First/Previous/Next/Last word labels (`7.1.0.2026072306`)
- [x] Support Worker → Client: New/Delete/Copy/Customize hidden via window-level Restrict (SQL `02-…`)

## AbilityERP Admin access

No new Window / Process / Info Window / Form.

| Access | Name | Search key |
|---|---|---|
| — | HCO ZK Theme (`org.hco.ui.theme`) | Theme preference / `ZK_THEME=hco` |

## Repository artifacts

- Plugin: `idempiere-plugins/org.hco.ui.theme/`
- Release JAR: `idempiere-plugins/org.hco.ui.theme/release/org.hco.ui.theme_7.1.0.2026072306.jar`
