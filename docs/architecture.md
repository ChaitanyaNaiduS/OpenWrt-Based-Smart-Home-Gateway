# Architecture

## Components

- Ubuntu host with KVM/QEMU
- One OpenWrt x86 VM acting as the gateway
- Linux bridge with VLAN filtering to emulate a trunk port
- Linux namespaces acting as trusted, IoT, and guest clients
- `openNDS` on OpenWrt for guest captive portal
- `tc` with HTB for QoS

## Logical Layout

```text
                    Internet
                       |
                QEMU user-mode NAT
                       |
                 OpenWrt VM eth0

     trusted-ns ----\
        iot-ns ------ access ports on br-lab (VLAN-aware) --- OpenWrt VM eth1 (trunk)
      guest-ns -----/
```

## VLAN Plan

| VLAN | Role    | Subnet          | Gateway       |
|------|---------|-----------------|---------------|
| 10   | trusted | 192.168.10.0/24 | 192.168.10.1  |
| 20   | iot     | 192.168.20.0/24 | 192.168.20.1  |
| 30   | guest   | 192.168.30.0/24 | 192.168.30.1  |

## Security Model

- `trusted` may reach WAN and optionally manage OpenWrt
- `iot` may reach WAN but is blocked from `trusted`
- `guest` may reach the captive portal and WAN after authentication
- Inter-VLAN forwarding is denied by default except for explicitly allowed flows

## Why This Works Without Hardware

The lab emulates switching, trunking, and clients entirely in software:

- VLAN tagging is handled by Linux bridge VLAN filtering
- Each namespace behaves like a separate endpoint
- OpenWrt handles routing, DHCP, NAT, firewall policy, and portal logic exactly as it would on physical hardware

The only thing missing is actual radio transmission. That means this is ideal for proving network design, segmentation, policy enforcement, and monitoring logic before moving to a real access point.
