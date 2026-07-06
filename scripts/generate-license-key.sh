#!/bin/zsh
# Generate a dev/test Respiro license key (RESPIRO-XXXX-XXXX-CC).
set -e
R1=$(openssl rand -hex 2 | tr 'a-f' 'A-F' | cut -c1-4)
R2=$(openssl rand -hex 2 | tr 'a-f' 'A-F' | cut -c1-4)
PAYLOAD="${R1}${R2}"
CC=$(python3 - <<PY
import hashlib
payload = "${PAYLOAD}"
b = hashlib.sha256(payload.encode()).digest()[0]
alpha = "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ"
print(alpha[(b >> 4) % len(alpha)] + alpha[(b & 0xF) % len(alpha)])
PY
)
echo "RESPIRO-${R1}-${R2}-${CC}"
