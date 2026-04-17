#!/usr/bin/env sh
set -eu

TARGETS="${*:-1.1.1.1 8.8.8.8}"
DATE_UTC="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

echo "timestamp=${DATE_UTC}"
echo "hostname=$(uci -q get system.@system[0].hostname || echo unknown)"
echo "wan_ip=$(ubus call network.interface.wan status | jsonfilter -e '@[\"ipv4-address\"][0].address' 2>/dev/null || echo unknown)"
echo "cpu_load=$(cut -d' ' -f1-3 /proc/loadavg)"

for target in ${TARGETS}; do
  if ping -c 3 -W 2 "${target}" >/tmp/ping.out 2>/dev/null; then
    avg="$(awk -F'/' '/round-trip|rtt/ {print $(NF-1)}' /tmp/ping.out)"
    echo "ping_${target//./_}_avg_ms=${avg:-n/a}"
  else
    echo "ping_${target//./_}_avg_ms=timeout"
  fi
done

echo "interfaces:"
ip -brief address show | sed 's/^/  /'
