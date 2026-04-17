#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

LAB_BRIDGE="${LAB_BRIDGE:-br-lab}"
OPENWRT_TAP="${OPENWRT_TAP:-tap-openwrt-lan}"

create_bridge() {
  local bridge="$1"
  ip link show "${bridge}" >/dev/null 2>&1 || ip link add name "${bridge}" type bridge vlan_filtering 1
  ip link set "${bridge}" up
}

create_namespace_port() {
  local ns="$1"
  local veth_host="v-${ns}"
  local veth_ns="eth0"
  local vlan="$2"

  ip netns add "${ns}" 2>/dev/null || true
  ip link show "${veth_host}" >/dev/null 2>&1 || ip link add "${veth_host}" type veth peer name "${veth_ns}"
  ip link set "${veth_ns}" netns "${ns}"
  ip link set "${veth_host}" master "${LAB_BRIDGE}"
  bridge vlan del dev "${veth_host}" vid 1 >/dev/null 2>&1 || true
  bridge vlan add dev "${veth_host}" vid "${vlan}" pvid untagged
  ip link set "${veth_host}" up
  ip netns exec "${ns}" ip link set lo up
  ip netns exec "${ns}" ip link set "${veth_ns}" up
  ip netns exec "${ns}" dhclient -r "${veth_ns}" >/dev/null 2>&1 || true
}

create_bridge "${LAB_BRIDGE}"
ip tuntap add dev "${OPENWRT_TAP}" mode tap 2>/dev/null || true
ip link set "${OPENWRT_TAP}" master "${LAB_BRIDGE}"
bridge vlan del dev "${OPENWRT_TAP}" vid 1 >/dev/null 2>&1 || true
bridge vlan add dev "${OPENWRT_TAP}" vid 10
bridge vlan add dev "${OPENWRT_TAP}" vid 20
bridge vlan add dev "${OPENWRT_TAP}" vid 30
ip link set "${OPENWRT_TAP}" up

create_namespace_port trusted-ns 10
create_namespace_port iot-ns 20
create_namespace_port guest-ns 30

echo "Lab network created."
echo "Bridge: ${LAB_BRIDGE}"
echo "Tap: ${OPENWRT_TAP}"
echo "Namespaces: trusted-ns, iot-ns, guest-ns"
