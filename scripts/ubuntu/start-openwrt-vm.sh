#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
IMAGE_QCOW2="${BUILD_DIR}/openwrt.qcow2"
LAN_TAP="${LAN_TAP:-tap-openwrt-lan}"
SHARE_DIR="${PROJECT_ROOT}/vm-share"

mkdir -p "${SHARE_DIR}"

cp "${PROJECT_ROOT}/scripts/openwrt/provision-gateway.sh" "${SHARE_DIR}/provision-gateway.sh"
cp "${PROJECT_ROOT}/scripts/openwrt/configure-qos.sh" "${SHARE_DIR}/configure-qos.sh"
cp "${PROJECT_ROOT}/config/openwrt/opennds.conf" "${SHARE_DIR}/opennds.conf"
cp "${PROJECT_ROOT}/monitoring/bash/network-health.sh" "${SHARE_DIR}/network-health.sh"
cp "${PROJECT_ROOT}/monitoring/bash/dhcp-watch.sh" "${SHARE_DIR}/dhcp-watch.sh"
cp "${PROJECT_ROOT}/monitoring/python/firewall_metrics.py" "${SHARE_DIR}/firewall_metrics.py"
cp "${PROJECT_ROOT}/monitoring/python/perf_probe.py" "${SHARE_DIR}/perf_probe.py"

if [[ ! -f "${IMAGE_QCOW2}" ]]; then
  echo "Missing ${IMAGE_QCOW2}. Run download-openwrt.sh first." >&2
  exit 1
fi

qemu-system-x86_64 \
  -enable-kvm \
  -m 1024 \
  -smp 2 \
  -drive file="${IMAGE_QCOW2}",if=virtio,format=qcow2 \
  -nic user,model=virtio-net-pci \
  -netdev tap,id=lan0,ifname="${LAN_TAP}",script=no,downscript=no \
  -device virtio-net-pci,netdev=lan0 \
  -virtfs local,path="${SHARE_DIR}",mount_tag=hostshare,security_model=none,id=hostshare \
  -nographic
