# SAW032 — Deploy

**Ticket:** `SAW032_sms_staff_info_multiselect`  
**Bundle:** `com.aberp.rostering.staffinfo` **`1.1.0.2026072218`**  
**Prerequisite:** SAW003 Find & Fill UU `2b4ab146-0809-47c6-96f3-8b841d60a6bf` exists

## What this ships

1. SQL `28-clone-sms-multiselect-info.sql` — clones Info Window → SMS UU `7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11` (columns, trl, related, access). Idempotent.
2. JAR `2218` — factory/window route both UUs; SMS = multi-select, Find & Fill = single-select (caller flag ignored).

## Deploy (HCO / host with `$IDEMPIERE_HOME`)

```bash
cd idempiere-plugins/com.aberp.rostering.staffinfo
# SQL only (if JAR already planned separately):
sudo -u postgres psql -d idempiere -v ON_ERROR_STOP=1 -f sql/28-clone-sms-multiselect-info.sql

chmod +x build.sh
./build.sh
JAR=com.aberp.rostering.staffinfo_1.1.0.2026072218.jar
IDEMPIERE_HOME=${IDEMPIERE_HOME:-/opt/idempiere-server}
sudo rm -f $IDEMPIERE_HOME/plugins/com.aberp.rostering.staffinfo_*.jar
sudo rm -f $IDEMPIERE_HOME/customization-jar/com.aberp.rostering.staffinfo_*.jar
sudo cp build/dist/$JAR $IDEMPIERE_HOME/plugins/$JAR
sudo cp build/dist/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
sudo chown idempiere:idempiere $IDEMPIERE_HOME/plugins/$JAR $IDEMPIERE_HOME/customization-jar/$JAR
B=$IDEMPIERE_HOME/configuration/org.eclipse.equinox.simpleconfigurator/bundles.info
sudo sed -i '/^com.aberp.rostering.staffinfo,/d' "$B"
echo "com.aberp.rostering.staffinfo,1.1.0.2026072218,plugins/$JAR,4,true" | sudo tee -a "$B" >/dev/null
sudo systemctl restart idempiere
# Wait WebUI 200 → Cache Reset / logout-in
```

Or full plugin deploy: `./deploy.sh` (runs SQL through `28` + `04-verify` + JAR + restart).

## After deploy — assign SMS process

Set the SMS process (or its Info Window parameter) to UU:

`7c9e2a41-5b68-4d3f-a1e0-9f4c6b8d2e11`

Do **not** change Find & Fill / Response Log Find Fill off `2b4ab146-0809-47c6-96f3-8b841d60a6bf`.

## Smoke

| Check | Expect |
|-------|--------|
| Find & Fill from Shift Employee | Single-select; Related Info still works |
| SMS Info Window (menu or process) | Multi-select checkboxes |
| Both UUs in DB | Same column count |
| Filters | Same four ticks / credential behaviour as Find & Fill |
