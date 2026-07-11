#!/bin/bash
# Sync + deploy com.aberp.rostering.staffinfo to EC2 iDempiere.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN_DIR="$ROOT/idempiere-plugins/com.aberp.rostering.staffinfo"
EC2_HOST="${EC2_HOST:-ubuntu@ec2-54-206-120-32.ap-southeast-2.compute.amazonaws.com}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/AbilityERP_Development_Keypair_Shared.pem}"
REMOTE_DIR="/home/ubuntu/abilityerp-plugins/com.aberp.rostering.staffinfo"

rsync -az --delete \
  -e "ssh -i \"$SSH_KEY\" -o StrictHostKeyChecking=no" \
  --exclude 'build/' \
  --exclude 'release/' \
  --exclude '.git/' \
  "$PLUGIN_DIR/" "$EC2_HOST:$REMOTE_DIR/"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$EC2_HOST" \
  "chmod +x $REMOTE_DIR/build.sh $REMOTE_DIR/deploy.sh && sudo $REMOTE_DIR/deploy.sh"
