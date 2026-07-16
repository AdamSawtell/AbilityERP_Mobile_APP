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
3. Toolbar **Refresh Compliance** → stub success message
4. Child tabs still present
5. **Compliance Rules** opens

## Dev install evidence

- 2026-07-16: skeleton through rename — org header 76.4 / Red
- Phase 2: Refresh button + OSGi factory (see NOTES after deploy)

## Blockers / later

- Phase 3: live rules / snapshots
- Phase 4: Audit Results Info Window + packs
- Support Location FK = `AbERP_Support_Location_ID` → `aberp_support_location`
