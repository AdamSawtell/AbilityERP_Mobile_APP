# SAW023 — Deploy (NDIS Audit Tool / Compliance & Audit Hub)

## Hosts

| Env | Host | Notes |
|-----|------|-------|
| Dev | `3.27.207.215` | Primary install host |
| HCO | See `Tickets/HCO_Deployment/` | Later — never change HCO `*_UU` |

SSH (dev): `ubuntu@3.27.207.215` with `C:\Users\sawte\Documents\SSH Keys\HCObusiness.pem`

## JAR

**Yes:** `com.aberp.compliance_7.1.0.202607161100.jar`

```bash
cd /path/to/idempiere-plugins/com.aberp.compliance
chmod +x build.sh deploy.sh
./deploy.sh
```

## SQL order

`sql/00` … `sql/17` via `install-all.sh`, or ClientUpdate pack `sql/` folder.

Key adds: `14` Refresh button, `15`–`16` rules, `17` Compliance Results Info Window.

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Window | Compliance Rules | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |
| Info Window | Compliance Results | — |

## Smoke

1. **NDIS Audit Tool** → **Refresh Compliance** (all categories)
2. ReQuery KPIs
3. **Compliance Results** Info Window — filter Status / Severity
4. **Compliance Rules** — 10 rules

## Packs (2026-07-16)

- Staging: `C:\Users\sawte\Downloads\AbilityERP-ClientUpdate-SAW023_compliance_audit_hub-20260716`
- Production: `C:\Users\sawte\Downloads\AbilityERP-ProdUpdate-SAW023_compliance_audit_hub-20260716`

## Notes

- Missing Service Agreement rule is seeded but skipped when SA table has no date model / rows
- Credential-need rostering rule can produce large result sets (next 14 days)
