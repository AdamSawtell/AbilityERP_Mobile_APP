#!/bin/bash
# Deploy AbERP Unavailability Planning Info (SQL AD + Java InfoWindow).
set -euo pipefail
exec "$(cd "$(dirname "$0")" && pwd)/rebuild-hco.sh"
