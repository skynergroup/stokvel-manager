#!/usr/bin/env bash
#
# Waits for the docker-android emulator to become ready.
# Polls `docker exec CONTAINER cat device_status` until it reports "ready".
#
# Usage: wait-for-emulator.sh CONTAINER [TIMEOUT_SECONDS]
#   CONTAINER        - Name or ID of the docker-android container.
#   TIMEOUT_SECONDS  - Max seconds to wait (default: 120).
#
set -euo pipefail

CONTAINER="${1:-}"
TIMEOUT="${2:-120}"

if [ -z "$CONTAINER" ]; then
  echo "Usage: $0 CONTAINER [TIMEOUT_SECONDS]" >&2
  exit 1
fi

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "Error: TIMEOUT must be a positive integer." >&2
  exit 1
fi

echo "Waiting for emulator in container '$CONTAINER' to become ready (timeout: ${TIMEOUT}s)..."

ELAPSED=0
INTERVAL=5

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  STATUS=$(docker exec "$CONTAINER" cat device_status 2>/dev/null || echo "unknown")

  if [ "$STATUS" = "ready" ]; then
    echo "Emulator is ready after ${ELAPSED}s."
    exit 0
  fi

  echo "  Status: $STATUS (${ELAPSED}s elapsed)"
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "Error: Emulator did not become ready within ${TIMEOUT}s." >&2
exit 1
