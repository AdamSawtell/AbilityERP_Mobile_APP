# SAW032 — Production deploy (HCO)

**Status:** Installed on HCO Production (2026-07-22) — operator smoke  
**GitHub:** [#32](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/32)  
**Bundle:** `com.aberp.rostering.staffinfo` **`1.1.0.2026072218`**  
**Verified on:** HCO Test `https://3.25.213.143/webui/` (user-tested 2026-07-22)

## Production target

| | |
|--|--|
| Host | `13.239.162.141` (`HCOproduction`) |
| SSH | `ubuntu@13.239.162.141` + `Documents\SSH Keys\HCO_Prod_KP.pem` |
| WebUI | `https://abilityerp.hco.net.au/webui/` |
| iDempiere home | `/opt/idempiere-server` |
| Current prod JAR (before this push) | `1.1.0.2026071517` (~52 KB) |
| Find & Fill UU (already present) | `2b4ab146-0809-47c6-96f3-8b841d60a6bf` |
| SMS UU (created by SQL `28`) | `7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11` |

Hard rules:

- Do **not** change any existing HCO `*_UU`.
- Do **not** run full `./deploy.sh` on Production (re-runs SAW003 SQL history).
- Ship **SQL `28` + JAR `2218` only**, then restart + Cache Reset.

## What Production gets

| Piece | Effect |
|-------|--------|
| SQL `28` | New SMS Info Window + optional menu (idempotent). Find & Fill untouched. |
| JAR `2218` | Replaces `1517`. Same plugin serves both UUs: Find & Fill = **single-select**; SMS = **multi-select**. Also includes SAW003 fixes already on Test (`2214`: `TO_TIMESTAMP` overlap/leave, Partner Location suburb behaviour already in AD if SQL `26` was applied in HCO20260714). |

Find & Fill behaviour stays single-select by UU — callers cannot flip it to multi.

## Prebuilt artifacts (git `main`)

- JAR: `idempiere-plugins/com.aberp.rostering.staffinfo/release/com.aberp.rostering.staffinfo_1.1.0.2026072218.jar` (~77 KB; reject ~29 KB / ~52 KB stale)
- SQL: `idempiere-plugins/com.aberp.rostering.staffinfo/sql/28-clone-sms-multiselect-info.sql`

## Production install (copy/paste)

```bash
# On laptop (from repo root)
KEY="$HOME/Documents/SSH Keys/HCO_Prod_KP.pem"   # Windows path as used locally
HOST=ubuntu@13.239.162.141
PLUGIN=idempiere-plugins/com.aberp.rostering.staffinfo
scp -i "$KEY" "$PLUGIN/sql/28-clone-sms-multiselect-info.sql" \
  "$PLUGIN/release/com.aberp.rostering.staffinfo_1.1.0.2026072218.jar" \
  $HOST:/tmp/

# On host
sed -i 's/\r$//' /tmp/28-clone-sms-multiselect-info.sql
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f /tmp/28-clone-sms-multiselect-info.sql

JAR=com.aberp.rostering.staffinfo_1.1.0.2026072218.jar
IDEMPIERE_HOME=/opt/idempiere-server
sudo rm -f $IDEMPIERE_HOME/plugins/com.aberp.rostering.staffinfo_*.jar
sudo rm -f $IDEMPIERE_HOME/customization-jar/com.aberp.rostering.staffinfo_*.jar
sudo cp /tmp/$JAR $IDEMPIERE_HOME/plugins/$JAR
sudo cp /tmp/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
sudo chown idempiere:idempiere $IDEMPIERE_HOME/plugins/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
B=$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i '/^com.aberp.rostering.staffinfo,/d' "$B"
echo "com.aberp.rostering.staffinfo,1.1.0.2026072218,plugins/$JAR,4,true" | sudo tee -a "$B" >/dev/null
grep staffinfo "$B"

# Prefer stop → start if restart leaves Java stuck
sudo systemctl stop idempiere
sleep 3
# if Java still up: sudo pkill -f equinox  (only if confirmed leftover)
sudo systemctl start idempiere
# Wait WebUI 200 on https://abilityerp.hco.net.au/webui/
```

Then: **Cache Reset** (or logout/in) as Admin.

## After install — SMS process (operator)

Point the SMS process / search at:

`7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11`

Leave Find & Fill / Response Log Find Fill on:

`2b4ab146-0809-47c6-96f3-8b841d60a6bf`

Menu (optional, created by SQL `28`): `Employee (User) / Agency Staff Rostering Info (SMS)` · menu UU `a8f3c2d1-5e6b-4a7c-9d0e-1f2a3b4c5d6e`

## Verify SQL

```sql
SELECT ad_infowindow_id, name, ad_infowindow_uu, isactive, isvalid
FROM adempiere.ad_infowindow
WHERE ad_infowindow_uu IN (
  '2b4ab146-0809-47c6-96f3-8b841d60a6bf',
  '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11'
);

SELECT iw.name, COUNT(c.*) AS columns
FROM adempiere.ad_infowindow iw
JOIN adempiere.ad_infocolumn c ON c.ad_infowindow_id = iw.ad_infowindow_id
WHERE iw.ad_infowindow_uu IN (
  '2b4ab146-0809-47c6-96f3-8b841d60a6bf',
  '7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11'
)
GROUP BY iw.name;
-- Expect matching column counts on both windows
```

## Smoke (Production)

| # | Check | Expect |
|---|-------|--------|
| 1 | `bundles.info` | `com.aberp.rostering.staffinfo,1.1.0.2026072218,…` |
| 2 | Both Info Window UUs present | SMS new; Find & Fill unchanged UU |
| 3 | Shift → Employee → Find & Fill | **Single-select**; Related Info follows one row |
| 4 | Menu **…Rostering Info (SMS)** (or SMS process) | **Multi-select** row checkboxes |
| 5 | Four filter ticks | Same defaults as Find & Fill |

## Rollback

1. Restore previous JAR `1.1.0.2026071517` into `plugins/` + `customization-jar/` and `bundles.info` line.  
2. Restart iDempiere.  
3. SMS Info Window / menu can remain in AD (harmless) or deactivate `isactive='N'` on SMS UU / menu UU if preferred. Do **not** delete Find & Fill.

## Environments

| Env | Host | State |
|-----|------|--------|
| HCO Test | `https://3.25.213.143/webui/` | **PASS** — SQL `28` + JAR `2218` · user-tested |
| HCO Production | `https://abilityerp.hco.net.au/webui/` · `13.239.162.141` | **Installed 2026-07-22** — SQL `28` + JAR `2218` (was `1517`); operator smoke |
