# SAW016 — Checklist

## Staging (HCO Test `32.236.127.117`)

- [x] Preflight + install path documented
- [x] JAR `1.0.0.2026071402` + SQL through `24-support-location-search-nonneg.sql`
- [x] Deploy handoff: [`DEPLOY.md`](DEPLOY.md) + [`redeploy-hco.sh`](../../idempiere-plugins/com.aberp.leave.planning/redeploy-hco.sh)
- [ ] **Post host rebuild:** run `redeploy-hco.sh` → Cache Reset → full WebUI smoke in DEPLOY.md
- [ ] Mark done when EXTERNAL-SUMMARY accepted + packs current

## Smoke after redeploy (copy from DEPLOY)

- [ ] Labels **Support Location**; Jul 2026 ~46 rows; no AccessSqlParser error
- [ ] Location Search (`1/6 Murray`) → no non-neg popup; fewer rows
- [ ] Banner / colours / Export CSV / Zoom

## Acceptance mapping

- [x] Leave Planning Info Window
- [x] Date Start/End; optional Support Location (blank = all)
- [x] Overlap matching; roster Support Location (not home)
- [x] Status banner + Approver Status colours
- [x] Zoom to underlying leave
- [x] Export CSV (no AMedia)
- [x] Migration under `idempiere-plugins/com.aberp.leave.planning/sql/`
