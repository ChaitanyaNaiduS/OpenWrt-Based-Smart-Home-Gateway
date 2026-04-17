#!/usr/bin/env sh
set -eu

LEASE_FILE="${LEASE_FILE:-/tmp/dhcp.leases}"
INTERVAL="${INTERVAL:-5}"

echo "Watching ${LEASE_FILE} every ${INTERVAL}s"

while true; do
  clear
  date -u '+%Y-%m-%dT%H:%M:%SZ'
  echo
  if [ -f "${LEASE_FILE}" ]; then
    awk '
      {
        printf "expires=%s mac=%s ip=%s host=%s clientid=%s\n", $1, $2, $3, $4, $5
      }
    ' "${LEASE_FILE}"
  else
    echo "Lease file not found."
  fi
  sleep "${INTERVAL}"
done
