# SAW029 — Deploy

## Environment

| Tier | Host | Notes |
|------|------|--------|
| Dev | `3.27.207.215` | Audit Tool Build / HCO Test clone |
| SSH | `ubuntu@3.27.207.215` | Key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| WebUI | `http://3.27.207.215/webui/` | SuperUser / `HCOflamingo` · role **Admin** |

## Plugin

`idempiere-plugins/com.aberp.activityaudit/` (AD only for this ticket)

## JAR

No — `jar/NO-JAR.txt` in packs. Requires SAW027 Activity Audit Review window already present.

## Ordered SQL

1. Preflight: window **Activity Audit Review** / tab **Reviews** exists (UU `27a02750-…` / `27a02751-…` or name)
2. `sql/18-review-field-groups.sql`

## Restart / cache

No restart required for field groups. **Cache Reset** (or logout/in) before WebUI smoke.

## Smoke

1. Open **Activity Audit Review** → pick a row → Form view
2. Confirm collapsible groups: **Activity**, **Match**, **Review**, **Audit** (Audit collapsed)
3. **Open Activity** still in Activity group and works
4. Grid columns still show queue essentials (date, client, employee, terms, risk, status)

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Review | — |

Install SQL does not add new processes. Existing window access from SAW027 remains.
