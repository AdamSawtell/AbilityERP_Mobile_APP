#!/bin/bash
# Run Activity Audit Nightly for HCO client via ProcessUtil-style AD_PInstance
# Uses iDempiere's org.adempiere.server process if available; fallback: direct Java classpath invoke
set -euo pipefail
IDEMPIERE_HOME=/opt/idempiere-server
export IDEMPIERE_HOME

# Create AD_PInstance and execute via SQL + wait is hard; instead use a one-shot Java helper
# compiled against plugin + base jars.

PLUGIN=/opt/ability-erp-pwa/idempiere-plugins/com.aberp.activityaudit
BASE=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.base_*.jar | head -1)
UTILS=$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.plugin.utils_*.jar | head -1)
JAR="$PLUGIN/build/dist/com.aberp.activityaudit_7.1.0.202607171000.jar"

cat > /tmp/Saw027Run.java <<'EOF'
import java.util.Properties;
import org.compiere.Adempiere;
import org.compiere.util.Env;
import org.compiere.util.Ini;
import com.aberp.activityaudit.engine.ActivityAuditEngine;

public class Saw027Run {
  public static void main(String[] args) throws Exception {
    Adempiere.startup(false);
    Properties ctx = Env.getCtx();
    Env.setContext(ctx, "#AD_Client_ID", 1000003);
    Env.setContext(ctx, "#AD_Org_ID", 0);
    Env.setContext(ctx, "#AD_User_ID", 100);
    Env.setContext(ctx, "#AD_Role_ID", 0);
    ActivityAuditEngine engine = new ActivityAuditEngine(ctx, null);
    String summary = engine.runNightly();
    System.out.println("SUMMARY=" + summary);
    for (String l : engine.getLogs()) System.out.println(l);
  }
}
EOF

javac -encoding UTF-8 -source 11 -target 11 -classpath "$BASE:$UTILS:$JAR" -d /tmp /tmp/Saw027Run.java
# Runtime needs full iDempiere env — may fail outside OSGi. Prefer WebUI.
echo "Compiled helper; attempting run (may need OSGi)..."
cd "$IDEMPIERE_HOME"
# Skip if no properties
if [ ! -f idempiereEnv.properties ] && [ ! -f Idempiere.properties ]; then
  echo "No properties for standalone run"
  exit 0
fi
java -classpath "/tmp:$BASE:$UTILS:$JAR:$IDEMPIERE_HOME/lib/*" Saw027Run || echo "Standalone run failed (expected without full server ctx)"
