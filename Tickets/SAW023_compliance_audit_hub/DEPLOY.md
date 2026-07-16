# SAW023 — Deploy (NDIS Audit Tool / Compliance & Audit Hub)

## Hosts

| Env | Host | Notes |
|-----|------|-------|
| Dev | `3.27.207.215` | Primary install host |
| HCO | See `Tickets/HCO_Deployment/` | Later — never change HCO `*_UU` |

SSH (dev): `ubuntu@3.27.207.215` with `C:\Users\sawte\Documents\SSH Keys\HCObusiness.pem`

## JAR

**Yes (Phase 2+):** `com.aberp.compliance_7.1.0.<timestamp>.jar`

On the iDempiere host (preferred):

```bash
cd /path/to/idempiere-plugins/com.aberp.compliance
chmod +x build.sh deploy.sh
./deploy.sh
```

`deploy.sh` builds the JAR, copies to `plugins/` + `customization-jar/`, updates `bundles.info`, applies `04` + `14` SQL, restarts iDempiere (does **not** clear OSGi cache).

Manual console alternative: install/start the bundle after copy, then Cache Reset.

## SQL order

From `idempiere-plugins/com.aberp.compliance/sql/`:

1. `00`–`13` skeleton + rename (see `install-all.sh`)
2. `14-refresh-compliance-process.sql` — Refresh process + Organisation Audit toolbar button

Or full: `bash install-all.sh` (SQL only). JAR still needs `./deploy.sh` or manual OSGi install.

Then **Cache Reset** / logout-in.

## AbilityERP Admin access

| Access | Name | Search key |
|--------|------|------------|
| Window | NDIS Audit Tool | — |
| Window | Compliance Rules | — |
| Process | Refresh Compliance | `AbERP_Compliance_Refresh` |

## Smoke

1. Open **NDIS Audit Tool** as Admin
2. Organisation Audit KPIs visible
3. Toolbar **Refresh Compliance** → live Employee evaluation summary (expired / 30d / screening counts)
4. ReQuery — Employee totals reflect live snapshot; other tabs carry forward prior values
5. **Compliance Rules** shows the three Employee rules

## Dev install evidence

- 2026-07-16: skeleton + rename + Phase 2 stub
- Phase 3: Refresh `expired=123, due_in_30d=65, screening_expired=8`; W snapshot 9060 / 98.20 / Red

## Blockers / later

- Phase 3b: other categories
- Phase 4: Audit Results Info Window + packs
- Support Location FK = `AbERP_Support_Location_ID` → `aberp_support_location`
