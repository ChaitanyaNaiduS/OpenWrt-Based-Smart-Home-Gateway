# OpenWrt Smart Home Gateway Lab on Ubuntu

This project turns your router idea into a lab you can run on an Ubuntu machine without physical hardware. It uses an OpenWrt x86 virtual machine, an emulated VLAN trunk, a captive portal for the guest network, QoS with `tc` and HTB, and monitoring scripts for DHCP, firewall, and network performance.

## What This Lab Demonstrates

- OpenWrt gateway running as a QEMU/KVM virtual machine
- Segmented `trusted`, `iot`, and `guest` networks over separate VLANs
- Guest captive portal using `openNDS`
- QoS traffic shaping using `tc` and HTB
- Bash and Python monitoring for network health, DHCP activity, and firewall metrics

## Lab Topology

- `WAN`: QEMU user-mode NAT uplink for safe internet access from the VM
- `LAN trunk`: one virtual NIC from Ubuntu into OpenWrt carrying VLANs
- `VLAN 10`: trusted clients
- `VLAN 20`: IoT clients
- `VLAN 30`: guest clients with captive portal

Client devices are emulated with Linux network namespaces on Ubuntu, so you can test segmentation and portal behavior without any physical clients.

## Directory Layout

- [`docs/architecture.md`](/C:/Users/surla/OneDrive/Desktop/openwrt/docs/architecture.md)
- [`scripts/ubuntu/setup-host.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/scripts/ubuntu/setup-host.sh)
- [`scripts/ubuntu/create-lab-network.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/scripts/ubuntu/create-lab-network.sh)
- [`scripts/ubuntu/download-openwrt.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/scripts/ubuntu/download-openwrt.sh)
- [`scripts/ubuntu/start-openwrt-vm.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/scripts/ubuntu/start-openwrt-vm.sh)
- [`scripts/ubuntu/test-clients.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/scripts/ubuntu/test-clients.sh)
- [`scripts/openwrt/provision-gateway.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/scripts/openwrt/provision-gateway.sh)
- [`scripts/openwrt/configure-qos.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/scripts/openwrt/configure-qos.sh)
- [`config/openwrt/opennds.conf`](/C:/Users/surla/OneDrive/Desktop/openwrt/config/openwrt/opennds.conf)
- [`monitoring/bash/network-health.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/monitoring/bash/network-health.sh)
- [`monitoring/bash/dhcp-watch.sh`](/C:/Users/surla/OneDrive/Desktop/openwrt/monitoring/bash/dhcp-watch.sh)
- [`monitoring/python/firewall_metrics.py`](/C:/Users/surla/OneDrive/Desktop/openwrt/monitoring/python/firewall_metrics.py)
- [`monitoring/python/perf_probe.py`](/C:/Users/surla/OneDrive/Desktop/openwrt/monitoring/python/perf_probe.py)

## Quick Start on Ubuntu

1. Install Ubuntu packages:
   ```bash
   chmod +x scripts/ubuntu/*.sh
   sudo scripts/ubuntu/setup-host.sh
   ```
2. Download the OpenWrt x86 image:
   ```bash
   ./scripts/ubuntu/download-openwrt.sh
   ```
3. Create the lab VLAN/access network:
   ```bash
   sudo ./scripts/ubuntu/create-lab-network.sh
   ```
4. Start the OpenWrt VM:
   ```bash
   sudo ./scripts/ubuntu/start-openwrt-vm.sh
   ```
5. In the OpenWrt console, mount the shared folder and copy in the lab bundle:
   ```sh
   mkdir -p /mnt
   mount -t 9p -o trans=virtio hostshare /mnt
   cp /mnt/* /root/
   chmod +x /root/*.sh
   ```
6. Run the OpenWrt provisioning and QoS scripts:
   ```sh
   sh /root/provision-gateway.sh
   sh /root/configure-qos.sh
   ```
7. Install captive portal packages in OpenWrt:
   ```sh
   opkg update
   opkg install opennds tcpdump ip-full python3
   cp /root/opennds.conf /etc/opennds/opennds.conf
   service opennds enable
   service opennds restart
   ```
8. Run the monitoring tools from OpenWrt:
   ```sh
   chmod +x /root/network-health.sh /root/dhcp-watch.sh
   /root/network-health.sh
   python3 /root/firewall_metrics.py --json
   python3 /root/perf_probe.py --targets 1.1.1.1 8.8.8.8
   ```
9. From Ubuntu, request DHCP leases for the emulated clients:
   ```bash
   chmod +x scripts/ubuntu/test-clients.sh
   sudo ./scripts/ubuntu/test-clients.sh
   ```

## Notes About Wi-Fi

Physical dual-band radios are not available in this VM lab. The segmented networks still exist as if they were separate SSIDs:

- `Trusted-5G` -> VLAN 10
- `IoT-2G` -> VLAN 20
- `Guest-Portal` -> VLAN 30

