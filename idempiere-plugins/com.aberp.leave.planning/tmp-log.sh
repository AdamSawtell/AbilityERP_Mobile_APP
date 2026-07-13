#!/bin/bash
L=$(ls -t /opt/idempiere-server/log/*.log | head -1)
echo "LOG=$L"
sudo sed -n '8755,8850p' "$L"
echo '===='
sudo sed -n '9005,9100p' "$L"
