#!/bin/bash
# SAW033 — build org.hco.ui.theme fragment from default theme + HCO overlay.
# Requires IDEMPIERE_HOME (default /opt/idempiere-server) with org.adempiere.ui.zk JAR.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PLUGIN_DIR/build"
STAGE_DIR="$BUILD_DIR/stage"
VERSION="$(grep '^Bundle-Version:' "$PLUGIN_DIR/META-INF/MANIFEST.MF" | awk '{print $2}' | tr -d '\r')"
JAR_NAME="org.hco.ui.theme_${VERSION}.jar"
IDEMPIERE_HOME="${IDEMPIERE_HOME:-/opt/idempiere-server}"
UIZK_JAR="$(ls "$IDEMPIERE_HOME"/plugins/org.adempiere.ui.zk_*.jar | head -1)"

if [[ -z "${UIZK_JAR:-}" || ! -f "$UIZK_JAR" ]]; then
  echo "ERROR: org.adempiere.ui.zk JAR not found under $IDEMPIERE_HOME/plugins" >&2
  exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$STAGE_DIR" "$BUILD_DIR/dist"

echo "Extracting default theme from $(basename "$UIZK_JAR")..."
(
  cd "$STAGE_DIR"
  jar xf "$UIZK_JAR" theme/default
  mv theme/default theme/hco
)

echo "Applying HCO overlay..."
mkdir -p "$STAGE_DIR/theme/hco/css/fragment"
cp -f "$PLUGIN_DIR/overlay/css/fragment/custom.css.dsp" "$STAGE_DIR/theme/hco/css/fragment/custom.css.dsp"

mkdir -p "$STAGE_DIR/theme/hco/zul/login"
cp -f "$PLUGIN_DIR/overlay/zul/login/"*.zul "$STAGE_DIR/theme/hco/zul/login/"

if [[ ! -f "$PLUGIN_DIR/overlay/images/login-logo.png" ]]; then
  echo "ERROR: missing overlay/images/login-logo.png" >&2
  exit 1
fi
cp -f "$PLUGIN_DIR/overlay/images/login-logo.png" "$STAGE_DIR/theme/hco/images/login-logo.png"
cp -f "$PLUGIN_DIR/overlay/images/header-logo.png" "$STAGE_DIR/theme/hco/images/header-logo.png"
cp -f "$PLUGIN_DIR/overlay/images/icon.png" "$STAGE_DIR/theme/hco/images/icon.png"
[[ -f "$PLUGIN_DIR/overlay/images/logo-mobile.png" ]] && \
  cp -f "$PLUGIN_DIR/overlay/images/logo-mobile.png" "$STAGE_DIR/theme/hco/images/logo-mobile.png"
[[ -f "$PLUGIN_DIR/overlay/images/favicon.ico" ]] && \
  cp -f "$PLUGIN_DIR/overlay/images/favicon.ico" "$STAGE_DIR/theme/hco/images/favicon.ico"

mkdir -p "$STAGE_DIR/metainfo/zk" "$STAGE_DIR/META-INF"
# OSGi requires LF-only MANIFEST (CRLF breaks Fragment-Host attach)
tr -d '\r' < "$PLUGIN_DIR/metainfo/zk/lang-addon.xml" > "$STAGE_DIR/metainfo/zk/lang-addon.xml"
tr -d '\r' < "$PLUGIN_DIR/META-INF/MANIFEST.MF" > "$STAGE_DIR/META-INF/MANIFEST.MF"
# normalize overlay text to LF
find "$STAGE_DIR/theme/hco/css/fragment/custom.css.dsp" "$STAGE_DIR/theme/hco/zul/login" -type f 2>/dev/null | while read -r f; do
  tr -d '\r' < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# Force HCO brand panel on login west; rewrite default theme paths
LOGIN_ZUL="$STAGE_DIR/theme/hco/zul/login/login.zul"
python3 - "$LOGIN_ZUL" <<'PY'
import sys, re
path = sys.argv[1]
text = open(path, encoding='utf-8').read()
text = text.replace('/theme/default/', '/theme/hco/')
text = re.sub(
    r'<include src="/theme/hco/zul/login/login-left\.zul"[^/]*/>',
    '<include src="/theme/hco/zul/login/login-left.zul"/>',
    text,
)
open(path, 'w', encoding='utf-8').write(text)
print('patched', path)
PY

find "$STAGE_DIR/theme/hco/zul" -type f -name '*.zul' -print0 | while IFS= read -r -d '' f; do
  sed -i 's#/theme/default/#/theme/hco/#g' "$f"
done

echo "HCO theme SAW033 ${VERSION}" > "$STAGE_DIR/plugin.info"

(
  cd "$STAGE_DIR"
  jar cfm "$BUILD_DIR/dist/$JAR_NAME" META-INF/MANIFEST.MF \
    theme metainfo plugin.info
)

# jar(1) may rewrite MANIFEST with CRLF — force LF-only for OSGi Fragment-Host
python3 - "$BUILD_DIR/dist/$JAR_NAME" "$STAGE_DIR/META-INF/MANIFEST.MF" <<'PY'
import sys, zipfile, tempfile, shutil, os
jar_path, mf_path = sys.argv[1], sys.argv[2]
mf = open(mf_path, 'rb').read().replace(b'\r\n', b'\n').replace(b'\r', b'\n')
if not mf.endswith(b'\n'):
    mf += b'\n'
tmp_fd, tmp_path = tempfile.mkstemp(suffix='.jar')
os.close(tmp_fd)
with zipfile.ZipFile(jar_path, 'r') as zin, zipfile.ZipFile(tmp_path, 'w') as zout:
    for item in zin.infolist():
        data = zin.read(item.filename)
        if item.filename == 'META-INF/MANIFEST.MF':
            data = mf
            # keep Created-By if jar added it
            if b'Created-By:' not in data:
                data = data.rstrip(b'\n') + b'\nCreated-By: AbilityERP SAW033\n'
        # store uncompressed for MANIFEST compatibility
        info = zipfile.ZipInfo(item.filename)
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = item.external_attr
        zout.writestr(info, data)
shutil.move(tmp_path, jar_path)
raw = zipfile.ZipFile(jar_path).read('META-INF/MANIFEST.MF')
assert b'\r' not in raw, 'MANIFEST still has CR'
print('MANIFEST LF-only OK')
PY

mkdir -p "$PLUGIN_DIR/release"
cp -f "$BUILD_DIR/dist/$JAR_NAME" "$PLUGIN_DIR/release/"
cp -f "$BUILD_DIR/dist/$JAR_NAME" "$PLUGIN_DIR/"
echo "Built $BUILD_DIR/dist/$JAR_NAME"
ls -lh "$BUILD_DIR/dist/$JAR_NAME"
