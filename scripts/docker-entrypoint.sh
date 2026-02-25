#!/bin/bash
set -e

STATE_DIR="${OPENCLAW_STATE_DIR:-/home/node/.openclaw}"
mkdir -p "$STATE_DIR"

CONFIG_FILE="$STATE_DIR/openclaw.json"

if [ ! -f "$CONFIG_FILE" ]; then
  # First boot: create minimal config with origin fallback enabled
  cat > "$CONFIG_FILE" <<'SEED'
{
  "gateway": {
    "mode": "local",
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
    }
  }
}
SEED
elif ! grep -q '"dangerouslyAllowHostHeaderOriginFallback"' "$CONFIG_FILE"; then
  # Existing config missing the flag: patch it in
  node -e "
    const fs = require('fs');
    const p = process.argv[1];
    const c = JSON.parse(fs.readFileSync(p, 'utf8'));
    c.gateway ??= {};
    c.gateway.controlUi ??= {};
    c.gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback = true;
    fs.writeFileSync(p, JSON.stringify(c, null, 2) + '\n');
  " "$CONFIG_FILE"
fi

exec "$@"
