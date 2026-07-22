# SAW033 — HCO iDempiere 7 theme plugin

**Status:** in-progress  
**Kind:** idempiere  
**GitHub:** [#33](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/33)  
**Slug:** `SAW033_hco_theme_plugin`

## Goal

Build an iDempiere 7 ZK theme plugin that overrides the default Dandelion look with HCO brand styling (CSS, images, ZK theme registration). No iDempiere core Java changes and no structural ZUL changes.

## Scope source

Obsidian: `AbilityERP/Development Scope/HCO iDempiere 7 Theme Plugin — Cursor Scope.md`

## Source paths

- `idempiere-plugins/org.hco.ui.theme/` (plugin source of truth — to be created)
- This ticket folder: deploy handoff, checklist, notes, external summary

## Staging target (this ticket)

| | |
|--|--|
| Host | `3.27.122.147` (hostname `ip-172-31-3-32`) |
| Role | HCO20260714 dry-run / Test001 (not Production) |
| SSH | `ubuntu@3.27.122.147` — key `C:\Users\sawte\Documents\SSH Keys\HCO_Prod_KP.pem` |
| iDempiere home | `/opt/idempiere-server` |
| Current theme | `ZK_THEME=default` |
| Related prod | `13.239.162.141` / `https://abilityerp.hco.net.au/webui/` — **out of scope until staging green** |

## Deliverables

1. Theme plugin JAR with `hco.css.dsp`, images, `plugin.xml` theme extension
2. Staging install + WebUI smoke on `3.27.122.147`
3. Client update packs after acceptance
4. Production promote handoff (separate step / agent after this ticket)

## Non-goals

- No core Java / no structural ZUL edits
- No direct production deploy in this ticket
- No AbilityERP mobile app changes
