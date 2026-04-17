#!/usr/bin/env bash
set -euo pipefail

declare -A TARGETS=(
  [trusted-ns]="${TRUSTED_TARGET:-192.168.10.1}"
  [iot-ns]="${IOT_TARGET:-192.168.20.1}"
  [guest-ns]="${GUEST_TARGET:-192.168.30.1}"
)

for ns in trusted-ns iot-ns guest-ns; do
  echo "=== ${ns} ==="
  ip netns exec "${ns}" dhclient eth0 || true
  ip netns exec "${ns}" ip -brief address show eth0
  ip netns exec "${ns}" ping -c 2 -W 2 "${TARGETS[${ns}]}" || true
  echo
done
