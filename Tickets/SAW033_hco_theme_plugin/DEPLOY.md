# SAW033 — Deploy HCO theme plugin

**Ticket / slug:** `SAW033_hco_theme_plugin`  
**Kind:** idempiere · **JAR:** yes · **SQL:** sysconfig (+ optional toolbar Restrict)  
**Status:** staging green · packs ready for further environments  
**Ship JAR:** `org.hco.ui.theme_7.1.0.2026072317.jar`

## Packs (primary handoff — use these, not git pull)

| Tier | Path |
|---|---|
| Staging / full | `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW033_hco_theme_plugin-20260723\` |
| Production (thin) | `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW033_hco_theme_plugin-20260723\` |

Each pack includes `theme-hco.tgz`, fragment JAR, inject script, SQL, and HOW-TO. Prefer pack install on any new host.

## Required host access

- SSH to iDempiere host
- Stop/start `idempiere` service
- `psql` on `idempiere` / `adempiere`
- WebUI admin login
- `jar` + `zip` on host (for inject script)

## Critical — Jetty 9.4 theme inject

Fragment JAR alone does **not** serve `/theme/hco/*` on this stack. Always:

1. Backup `org.adempiere.ui.zk_*.jar` → `*.pre-hco.bak` (once)
2. Inject `theme/hco` from `theme-hco.tgz` into that JAR
3. Register fragment in `bundles.info`
4. Apply theme SQL
5. Start + Cache Reset + hard-refresh

Never change existing client `*_UU` (HCO).

## Install from ProdUpdate pack (recommended for further env)

```bash
cd /tmp/AbilityERP-ProdUpdate-SAW033_hco_theme_plugin-20260723
sed -i 's/\r$//' inject-theme-hco.sh
chmod +x inject-theme-hco.sh
export IDEMPIERE_HOME=/opt/idempiere-server
bash inject-theme-hco.sh
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f 01-APPLY.sql
sudo /etc/init.d/idempiere start   # or systemctl
# wait WebUI 200 → Cache Reset → Ctrl+F5 → logout/in
```

### Optional — Support Worker toolbar Restrict (ClientUpdate only)

```bash
# from ClientUpdate pack sql/
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/02-toolbar-restrict-window-level.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/03-toolbar-showmore-and-restrict.sql
# Cache Reset or restart so MToolBarButtonRestrict reloads
```

These resolve HCO client / Support Worker by **name** — adjust or skip if target client name differs.

## Install from repo (staging rebuild only)

```bash
cd /opt/AbilityERP/idempiere-plugins/org.hco.ui.theme
sed -i 's/\r$//' build.sh deploy-hco-staging.sh
bash deploy-hco-staging.sh
# optional: sql/02 + sql/03 as above
```

## Ordered SQL (repo / ClientUpdate)

| # | File | Purpose |
|---|---|---|
| 00 | `00-preflight.sql` | Fail closed if sysconfig keys missing |
| 01 | `01-theme-sysconfig.sql` | `ZK_THEME=hco` + logos + login panel |
| 02 | `02-toolbar-restrict-window-level.sql` | Optional Support Worker Restrict |
| 03 | `03-toolbar-showmore-and-restrict.sql` | Optional ShowMore + Print Restrict |
| 99 | `99-rollback.sql` | Soft: `ZK_THEME=default` |

(`01-logo-sysconfig.sql` remains as logo-only helper; prefer `01-theme-sysconfig.sql`.)

## Rollback

```bash
sudo /etc/init.d/idempiere stop
sudo cp -a $IDEMPIERE_HOME/plugins/org.adempiere.ui.zk_*.jar.pre-hco.bak \
  $IDEMPIERE_HOME/plugins/org.adempiere.ui.zk_*.jar   # use actual filename
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f 99-ROLLBACK.sql
# optional: remove org.hco.ui.theme from bundles.info + plugins/
sudo /etc/init.d/idempiere start
```

## Smoke

- [ ] Login HCO logo + tagline + teal accents
- [ ] `/webui/theme/hco/css/theme.css.dsp` → 200
- [ ] Desktop header `#151515`, body `#eaeaea`, Poppins
- [ ] Query/search fields navy-on-white under OS dark mode
- [ ] Header username + Feedback/Preference/Change Role/Log Out white on dark
- [ ] Teal tab underline, toolbar tiles, grid headers `#00a2bd`
- [ ] Home favourites icons + roster status pills readable

## AbilityERP Admin access

No new Window / Process / Info Window / Form.

| Access | Name | Search key |
|---|---|---|
| — | HCO ZK Theme (`org.hco.ui.theme`) | Theme preference / `ZK_THEME=hco` |

## Staging evidence

| | |
|--|--|
| Host | `3.27.122.147` (`ip-172-31-3-32`) HCO Test001 dry-run |
| SSH | `ubuntu@…` — key `C:\Users\sawte\Documents\SSH Keys\HCO_Prod_KP.pem` |
| WebUI | `http://3.27.122.147/webui/` — `SuperUser` / `HCOflamingo` |
| JAR | `7.1.0.2026072317` |
| Validated | 2026-07-23 (incl. dark/light contrast) |

## Repository artifacts

- Plugin: `idempiere-plugins/org.hco.ui.theme/`
- Release JAR: `idempiere-plugins/org.hco.ui.theme/release/org.hco.ui.theme_7.1.0.2026072317.jar`
- Ticket: `Tickets/SAW033_hco_theme_plugin/`
