#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

apt-get update
apt-get install -y \
  qemu-system-x86 \
  qemu-utils \
  ovmf \
  iproute2 \
  bridge-utils \
  dnsutils \
  curl \
  wget \
  netcat-openbsd \
  python3 \
  python3-pip \
  isc-dhcp-client \
  tcpdump

echo "Ubuntu host packages installed."
