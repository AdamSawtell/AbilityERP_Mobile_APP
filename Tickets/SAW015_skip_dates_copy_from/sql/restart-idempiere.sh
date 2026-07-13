#!/bin/bash
set -e
IDEMPIERE_HOME=/opt/idempiere-server
echo "=== processes matching IDEMPIERE_HOME ==="
ps ax | grep -v grep | grep "$IDEMPIERE_HOME" || echo "(none)"
echo "=== forcing stop/start ==="
sudo /etc/init.d/idempiere stop || true
sleep 3
# clear false positives if any
ps ax | grep -v grep | grep "$IDEMPIERE_HOME" || echo "(none after stop)"
sudo /etc/init.d/idempiere start
echo "=== wait for webui ==="
for i in $(seq 1 40); do
  sleep 15
  CODE=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/webui/ || echo 000)
  echo "attempt $i: HTTP $CODE"
  if [ "$CODE" = "200" ]; then
    break
  fi
done
ps ax | grep -v grep | grep "$IDEMPIERE_HOME" | head -5
curl -s -o /dev/null -w 'final %{http_code}\n' http://127.0.0.1:8080/webui/ || true
