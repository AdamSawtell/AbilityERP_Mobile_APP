#!/bin/bash
set -e
# Prepare ordered one-zip dirs
BASE=/opt/idempiere-server/data/tmp/saw018
sudo mkdir -p "$BASE/1_credentials" "$BASE/2_employee" "$BASE/3_client" "$BASE/4_supportlocation"
sudo rm -f "$BASE"/1_credentials/* "$BASE"/2_employee/* "$BASE"/3_client/* "$BASE"/4_supportlocation/*
sudo cp "$BASE/hco_credentials.zip" "$BASE/1_credentials/"
sudo cp "$BASE/hco_employee.zip" "$BASE/2_employee/"
sudo cp "$BASE/hco_client.zip" "$BASE/3_client/"
sudo cp "$BASE/hco_supportlocation.zip" "$BASE/4_supportlocation/"
sudo chown -R idempiere:idempiere "$BASE"

# Run Apply Pack In from Folder via OSGi console (localhost:12612)
run_folder() {
  local folder="$1"
  local label="$2"
  echo "######## ApplyPackInFolder $label -> $folder ########"
  # Use expect to talk to OSGi console
  expect <<EOF
set timeout 300
spawn telnet localhost 12612
expect {
  -re "osgi>|g!" {}
  timeout { puts "TIMEOUT connect"; exit 1 }
}
send "runProcess ApplyPackInFolder Folder \"$folder\"\r"
expect {
  -re "osgi>|g!" {}
  timeout { puts "TIMEOUT process"; exit 1 }
}
send "disconnect\r"
expect eof
EOF
  PGPASSWORD=flamingo psql -h localhost -U adempiere -d idempiere -c \
    "SELECT ad_package_imp_id, name, pk_status, processed, created FROM adempiere.ad_package_imp ORDER BY created DESC LIMIT 5;"
}

# First check console help for runProcess
expect <<'EOF'
set timeout 30
spawn telnet localhost 12612
expect {
  -re "osgi>|g!" {}
  timeout { puts "TIMEOUT"; exit 1 }
}
send "help runProcess\r"
expect {
  -re "osgi>|g!" {}
  timeout {}
}
send "help\r"
expect {
  -re "osgi>|g!" {}
  timeout {}
}
send "disconnect\r"
expect eof
EOF