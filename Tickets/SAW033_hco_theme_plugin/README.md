# SAW033 — HCO iDempiere 7 theme plugin

**Status:** staging green · packs ready for further environments  
**Kind:** idempiere  
**GitHub:** [#33](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/33)  
**Slug:** `SAW033_hco_theme_plugin`  
**Ship JAR:** `org.hco.ui.theme_7.1.0.2026072317.jar`

## Goal

HCO brand ZK theme for iDempiere 7 WebUI (CSS, images, login branding). No core Java changes.

## Handoff for next agent

1. Read **`DEPLOY.md`** (install from Downloads packs — do not rely on git pull).
2. Use pack:
   - Full: `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW033_hco_theme_plugin-20260723\`
   - Thin: `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW033_hco_theme_plugin-20260723\`
3. Critical: inject `theme/hco` into `org.adempiere.ui.zk` (Jetty 9.4); fragment JAR alone is not enough.
4. Never change existing HCO `*_UU`.
5. Smoke checklist in DEPLOY.md; paste **`EXTERNAL-SUMMARY.md`** into the external ticket if needed.

## Source paths

- Plugin: `idempiere-plugins/org.hco.ui.theme/`
- This folder: DEPLOY / EXTERNAL-SUMMARY / NOTES / CHECKLIST

## Staging (validated)

| | |
|--|--|
| Host | `3.27.122.147` (HCO Test001 dry-run) |
| Theme | `ZK_THEME=hco` |
| JAR | `7.1.0.2026072317` |

Production promote is a separate step.
