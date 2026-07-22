# SAW033 — Deploy HCO theme plugin

**Ticket / slug:** `SAW033_hco_theme_plugin`  
**Kind:** idempiere · **JAR:** yes · **SQL:** none required for CSS theme  
**Status:** in-progress

## Required host access

- SSH to iDempiere host
- OSGi console (manual JAR install/start)
- WebUI admin login
- Cache Reset or logout/in; browser hard-refresh for CSS

## Staging host (current)

| | |
|--|--|
| Host | `3.27.122.147` (`ip-172-31-3-32`) |
| SSH | `ubuntu@3.27.122.147` |
| Key | `C:\Users\sawte\Documents\SSH Keys\HCO_Prod_KP.pem` |
| iDempiere | `/opt/idempiere-server` · 7.1 · ZK 8.6 |
| DB | `idempiere` / `adempiere` / `flamingo` (schema `adempiere`) — not required for JAR-only theme |
| WebUI | `http://3.27.122.147/webui/` |

This is the HCO20260714 dry-run / Test001 host (previous public IP `54.253.165.194`).  
**Not** HCO Production (`13.239.162.141`).

## Preflight

1. Confirm SSH and WebUI respond.
2. Confirm `org.adempiere.ui.zk` is present under `/opt/idempiere-server/plugins`.
3. Confirm no conflicting `org.hco.ui.theme` already installed (or plan stop/update of existing bundle).
4. Note current `ZK_THEME` / logo sysconfig values for rollback notes.

## Install

1. Copy built JAR to host (e.g. `/tmp/org.hco.ui.theme_….jar`).
2. On OSGi console: install (or update) the bundle, then `start` it.
3. Optionally set system preference / `ZK_THEME` to the HCO theme value once registered (document exact value after plugin defines it).
4. Cache Reset, logout/in, hard-refresh browser.

Exact console commands and final theme key will be filled after the plugin scaffold is built.

## Rollback

1. Stop/uninstall the HCO theme bundle (or revert to previous JAR).
2. Set `ZK_THEME` back to `default` (or prior value).
3. Cache Reset / re-login / hard-refresh.

## Smoke (must pass before packs / prod promote)

- [ ] Login page shows HCO logo / branding
- [ ] Window headers / buttons / menus use HCO palette
- [ ] Toolbar buttons are rounded teal tiles with hover lift
- [ ] Tabs are flat underline style
- [ ] Process/report dialogs have radius + shadow
- [ ] Record navigation matches toolbar styling
- [ ] Status bar has teal left accent
- [ ] Loading spinner is CSS teal circle
- [ ] No layout regressions on common windows (Shift, Employee, Invoice)
- [ ] Theme appears in user preference theme selector

## AbilityERP Admin access

No new Window / Process / Info Window / Form. Theme selection uses Preferences / `ZK_THEME`.

| Access | Name | Search key |
|---|---|---|
| — | HCO ZK Theme (`org.hco.ui.theme`) | Theme preference / `ZK_THEME` |

Grant nothing new for roles unless a later AD preference window binding is added.

## Repository artifacts

- Plugin: `idempiere-plugins/org.hco.ui.theme/` (source of truth)
- Packs: `Downloads\AbilityERP-ClientUpdate-SAW033_hco_theme_plugin-<YYYYMMDD>\` and thin ProdUpdate after staging green

## HCO hard rules

- Never change existing HCO `*_UU` values.
- Prefer name/UU lookups if any optional AD/sysconfig SQL is added later.
- Append `Tickets/HCO_Deployment/LEARNINGS.md` after each HCO install attempt.
