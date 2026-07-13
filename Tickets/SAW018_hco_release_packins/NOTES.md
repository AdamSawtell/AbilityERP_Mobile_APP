# SAW018 — NOTES

## Source

Original files: `D:\HCO Release Packins` (2026-03-13). Copied to `packins/`.

## HCO install 2026-07-13

Host: `32.236.127.117` (same as SAW010).

### Results

| Step | Result |
|------|--------|
| Clear stuck `ad_package_imp` | 5 rows cleared |
| Create `hco_cred_missing_staff_v` | OK |
| PackIn credentials / employee / client / supportlocation | All **Completed successfully** (`1001055`–`1001058`) |
| Support Location UU | Unchanged `6ef3c558-…` |

### Issues fixed (save for next env)

1. **Stuck package imports** blocked clean PackIn history — use `sql/00-clear-stuck-package-imp.sql`.  
2. **`RUN_ApplyPackInFromFolder.sh` initially failed** because legacy OSGi bundle `com.aberp.employee.infopanel` (Incremental2PackActivator) repeatedly failed: *Failed to save InfoWindow Employee (User) / Agency Staff Rostering Info* (pk_version 7.1.3+). Conflicts with SAW003 `com.aberp.rostering.staffinfo`.  
   - Fix: mark `com.aberp.employee.infopanel` versions 7.1.3–7.1.12 as `Completed successfully`; uninstall bundle `1332` from OSGi (was `inputstream:` install, not in `bundles.info`).  
3. **Zip naming** for folder apply must be `yyyymmddHHMM_SYSTEM_*.zip` (`AD_Client.Value` = `SYSTEM`).  
4. PackInFolderApplication shuts down after run — confirm `systemctl is-active idempiere` / start if needed.

### HCO Future Deployments variables

| Variable | Value |
|----------|--------|
| Host | `32.236.127.117` |
| DB | `idempiere` / `adempiere` / `flamingo` |
| System client Value | `SYSTEM` |
| Support Location window UU | `6ef3c558-3ec8-4f0c-be40-89f35d8acebf` |
| Credentials missing-staff table UU | `598a7584-4c57-4c31-8ea5-3b393d3d1e68` |
| Primary Department element UU | `daca9cb3-fe35-4193-95ff-dc99dc887692` |
| PackIn package_imp IDs (this run) | `1001055`–`1001058` |
| Named zip folder on host (this run) | `/opt/idempiere-server/data/tmp/saw018/named` |
| Legacy blocker bundle | `com.aberp.employee.infopanel` — uninstalled; prefer `com.aberp.rostering.staffinfo` |

## Packs

- `AbilityERP-ClientUpdate-SAW018_hco_release_packins-20260713`
- `AbilityERP-ProdUpdate-SAW018_hco_release_packins-20260713`
