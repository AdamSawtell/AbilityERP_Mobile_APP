#!/bin/bash
# Remote deploy helper: sync Contact Activity tabs plugin to EC2 and run deploy.
set -euo pipefail

EC2_HOST="${EC2_HOST:-ubuntu@ec2-54-206-120-32.ap-southeast-2.compute.amazonaws.com}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/AbilityERP_Development_Keypair_Shared.pem}"
REMOTE_DIR="/opt/ability-erp-pwa/idempiere-plugins/com.aberp.contactactivity.tabs"

scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -r \
  idempiere-plugins/com.aberp.contactactivity.tabs \
  "$EC2_HOST:/opt/ability-erp-pwa/idempiere-plugins/"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_HOST" \
  "chmod +x $REMOTE_DIR/build.sh $REMOTE_DIR/deploy.sh && sudo $REMOTE_DIR/deploy.sh"
