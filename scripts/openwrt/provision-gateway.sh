#!/bin/sh
set -eu

uci -q delete network.lan
uci -q delete network.globals
uci -q delete dhcp.lan
uci -q delete firewall.lan
uci -q delete firewall.wan
uci -q delete firewall.@forwarding[0]

uci batch <<'EOF'
set network.wan=interface
set network.wan.device='eth0'
set network.wan.proto='dhcp'

set network.trunk=device
set network.trunk.name='br-lan'
set network.trunk.type='bridge'
add_list network.trunk.ports='eth1'

add network bridge-vlan
set network.@bridge-vlan[-1].device='br-lan'
set network.@bridge-vlan[-1].vlan='10'
add_list network.@bridge-vlan[-1].ports='eth1:t'

add network bridge-vlan
set network.@bridge-vlan[-1].device='br-lan'
set network.@bridge-vlan[-1].vlan='20'
add_list network.@bridge-vlan[-1].ports='eth1:t'

add network bridge-vlan
set network.@bridge-vlan[-1].device='br-lan'
set network.@bridge-vlan[-1].vlan='30'
add_list network.@bridge-vlan[-1].ports='eth1:t'

set network.trusted_dev=device
set network.trusted_dev.type='8021q'
set network.trusted_dev.ifname='eth1'
set network.trusted_dev.vid='10'
set network.trusted_dev.name='eth1.10'

set network.iot_dev=device
set network.iot_dev.type='8021q'
set network.iot_dev.ifname='eth1'
set network.iot_dev.vid='20'
set network.iot_dev.name='eth1.20'

set network.guest_dev=device
set network.guest_dev.type='8021q'
set network.guest_dev.ifname='eth1'
set network.guest_dev.vid='30'
set network.guest_dev.name='eth1.30'

set network.trusted=interface
set network.trusted.proto='static'
set network.trusted.device='eth1.10'
set network.trusted.ipaddr='192.168.10.1'
set network.trusted.netmask='255.255.255.0'

set network.iot=interface
set network.iot.proto='static'
set network.iot.device='eth1.20'
set network.iot.ipaddr='192.168.20.1'
set network.iot.netmask='255.255.255.0'

set network.guest=interface
set network.guest.proto='static'
set network.guest.device='eth1.30'
set network.guest.ipaddr='192.168.30.1'
set network.guest.netmask='255.255.255.0'

set dhcp.trusted=dhcp
set dhcp.trusted.interface='trusted'
set dhcp.trusted.start='100'
set dhcp.trusted.limit='100'
set dhcp.trusted.leasetime='12h'

set dhcp.iot=dhcp
set dhcp.iot.interface='iot'
set dhcp.iot.start='100'
set dhcp.iot.limit='100'
set dhcp.iot.leasetime='24h'

set dhcp.guest=dhcp
set dhcp.guest.interface='guest'
set dhcp.guest.start='100'
set dhcp.guest.limit='150'
set dhcp.guest.leasetime='4h'

set firewall.@defaults[0].input='REJECT'
set firewall.@defaults[0].output='ACCEPT'
set firewall.@defaults[0].forward='REJECT'

add firewall zone
set firewall.@zone[-1].name='wan'
add_list firewall.@zone[-1].network='wan'
set firewall.@zone[-1].input='REJECT'
set firewall.@zone[-1].output='ACCEPT'
set firewall.@zone[-1].forward='REJECT'
set firewall.@zone[-1].masq='1'
set firewall.@zone[-1].mtu_fix='1'

add firewall zone
set firewall.@zone[-1].name='trusted'
add_list firewall.@zone[-1].network='trusted'
set firewall.@zone[-1].input='ACCEPT'
set firewall.@zone[-1].output='ACCEPT'
set firewall.@zone[-1].forward='REJECT'

add firewall zone
set firewall.@zone[-1].name='iot'
add_list firewall.@zone[-1].network='iot'
set firewall.@zone[-1].input='REJECT'
set firewall.@zone[-1].output='ACCEPT'
set firewall.@zone[-1].forward='REJECT'

add firewall zone
set firewall.@zone[-1].name='guest'
add_list firewall.@zone[-1].network='guest'
set firewall.@zone[-1].input='REJECT'
set firewall.@zone[-1].output='ACCEPT'
set firewall.@zone[-1].forward='REJECT'

add firewall forwarding
set firewall.@forwarding[-1].src='trusted'
set firewall.@forwarding[-1].dest='wan'

add firewall forwarding
set firewall.@forwarding[-1].src='iot'
set firewall.@forwarding[-1].dest='wan'

add firewall forwarding
set firewall.@forwarding[-1].src='guest'
set firewall.@forwarding[-1].dest='wan'

add firewall rule
set firewall.@rule[-1].name='Allow-DHCP-Guest'
set firewall.@rule[-1].src='guest'
set firewall.@rule[-1].proto='udp'
set firewall.@rule[-1].dest_port='67-68'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-DNS-Guest'
set firewall.@rule[-1].src='guest'
set firewall.@rule[-1].proto='tcp udp'
set firewall.@rule[-1].dest_port='53'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-Portal-HTTP'
set firewall.@rule[-1].src='guest'
set firewall.@rule[-1].proto='tcp'
set firewall.@rule[-1].dest_port='2050'
set firewall.@rule[-1].target='ACCEPT'

add firewall rule
set firewall.@rule[-1].name='Allow-Ping-Trusted'
set firewall.@rule[-1].src='trusted'
set firewall.@rule[-1].proto='icmp'
set firewall.@rule[-1].target='ACCEPT'
EOF

uci set system.@system[0].hostname='openwrt-gateway-lab'
uci set system.@system[0].zonename='America/New_York'
uci set system.@system[0].timezone='EST5EDT,M3.2.0,M11.1.0'

uci commit network
uci commit dhcp
uci commit firewall
uci commit system

/etc/init.d/network restart
/etc/init.d/dnsmasq restart
/etc/init.d/firewall restart

echo "Provisioning complete."
