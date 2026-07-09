#!/usr/bin/env bash
API="http://127.0.0.1:3001/api/auth/login"
for user in abilitya ewilliam gwilson asawtell; do
  echo "=== $user ==="
  curl -s -X POST "$API" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${user}\",\"password\":\"flamingo\"}"
  echo
done
