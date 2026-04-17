#!/bin/sh
set -eu

WAN_DEV="${WAN_DEV:-eth0}"
UPLINK_KBIT="${UPLINK_KBIT:-20000}"
DOWNLINK_KBIT="${DOWNLINK_KBIT:-100000}"
TRUSTED_RATE="${TRUSTED_RATE:-12000kbit}"
IOT_RATE="${IOT_RATE:-5000kbit}"
GUEST_RATE="${GUEST_RATE:-3000kbit}"

tc qdisc del dev "${WAN_DEV}" root 2>/dev/null || true
tc qdisc add dev "${WAN_DEV}" root handle 1: htb default 30

tc class add dev "${WAN_DEV}" parent 1: classid 1:1 htb rate "${UPLINK_KBIT}kbit" ceil "${UPLINK_KBIT}kbit"
tc class add dev "${WAN_DEV}" parent 1:1 classid 1:10 htb rate "${TRUSTED_RATE}" ceil "${UPLINK_KBIT}kbit" prio 0
tc class add dev "${WAN_DEV}" parent 1:1 classid 1:20 htb rate "${IOT_RATE}" ceil "${UPLINK_KBIT}kbit" prio 1
tc class add dev "${WAN_DEV}" parent 1:1 classid 1:30 htb rate "${GUEST_RATE}" ceil "${UPLINK_KBIT}kbit" prio 2

tc qdisc add dev "${WAN_DEV}" parent 1:10 handle 110: sfq perturb 10
tc qdisc add dev "${WAN_DEV}" parent 1:20 handle 120: sfq perturb 10
tc qdisc add dev "${WAN_DEV}" parent 1:30 handle 130: sfq perturb 10

tc filter add dev "${WAN_DEV}" protocol ip parent 1:0 prio 1 u32 match ip src 192.168.10.0/24 flowid 1:10
tc filter add dev "${WAN_DEV}" protocol ip parent 1:0 prio 2 u32 match ip src 192.168.20.0/24 flowid 1:20
tc filter add dev "${WAN_DEV}" protocol ip parent 1:0 prio 3 u32 match ip src 192.168.30.0/24 flowid 1:30

echo "QoS applied on ${WAN_DEV}"
echo "Configured downlink hint: ${DOWNLINK_KBIT}kbit"
