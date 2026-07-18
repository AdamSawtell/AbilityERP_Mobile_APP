# SAW030 — Deploy

## Prerequisites

- SAW003 Staff Rostering Info active (Info UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf`)
- Shift (Rostered) → Response Log tab present

## Install order

1. Build / copy JAR: `com.aberp.rostering.staffinfo_1.1.0.202607181830.jar`
   - From plugin: `bash build.sh` then copy to `plugins/` + `customization-jar/`, update `bundles.info`
2. Apply SQL: `idempiere-plugins/com.aberp.rostering.staffinfo/sql/27-response-log-find-fill.sql`
3. Restart iDempiere **or** OSGi refresh/start the staffinfo bundle
4. Cache Reset or log out/in

## AbilityERP Admin access

Granted in SQL to **Admin**, **AbilityERP Admin**, **Rostering**, **Rostering TL**, **Rostering Officer**.

| Access | Name | Search key |
|--------|------|------------|
| Process | Find and Fill | `AbERP_ResponseLog_FindFill` |
| Info Window | Employee (User) / Agency Staff Rostering Info | — |
| Window | Shift (Rostered) | — |

## Smoke

1. Open Shift (Rostered) with a vacant Employee line and an unreviewed Response Log row with a worker
2. Response Log → **Find and Fill**
3. Confirm Info opens with worker name prefilled and shift banner/filters
4. Select the worker → OK
5. Confirm Employee line filled, Response Log **Reviewed**, shift Published when applicable

## Rollback

- Deactivate field/process for `AbERP_FindFillStaff` / `AbERP_ResponseLog_FindFill`
- Revert staffinfo JAR to prior version if needed
