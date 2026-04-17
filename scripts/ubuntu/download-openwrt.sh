#!/usr/bin/env bash
set -euo pipefail

OPENWRT_VERSION="${OPENWRT_VERSION:-23.05.5}"
OPENWRT_TARGET_URL="${OPENWRT_TARGET_URL:-https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img.gz}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
IMAGE_GZ="${BUILD_DIR}/openwrt.img.gz"
IMAGE_RAW="${BUILD_DIR}/openwrt.img"
IMAGE_QCOW2="${BUILD_DIR}/openwrt.qcow2"

mkdir -p "${BUILD_DIR}"

if [[ ! -f "${IMAGE_GZ}" ]]; then
  wget -O "${IMAGE_GZ}" "${OPENWRT_TARGET_URL}"
fi

if [[ ! -f "${IMAGE_RAW}" ]]; then
  gunzip -c "${IMAGE_GZ}" > "${IMAGE_RAW}"
fi

if [[ ! -f "${IMAGE_QCOW2}" ]]; then
  qemu-img convert -f raw -O qcow2 "${IMAGE_RAW}" "${IMAGE_QCOW2}"
  qemu-img resize "${IMAGE_QCOW2}" +512M
fi

echo "Prepared ${IMAGE_QCOW2}"
