#!/usr/bin/env python3
"""Collect lightweight firewall counters from OpenWrt."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import dataclass, asdict


RULE_PATTERN = re.compile(
    r"^\s*(?P<pkts>\d+)\s+(?P<bytes>\d+)\s+(?P<target>\S+)\s+(?P<proto>\S+)\s+--\s+(?P<in>\S+)\s+(?P<out>\S+)\s+(?P<src>\S+)\s+(?P<dst>\S+)(?P<extra>.*)$"
)


@dataclass
class RuleMetric:
    chain: str
    packets: int
    bytes: int
    target: str
    proto: str
    in_iface: str
    out_iface: str
    source: str
    destination: str
    extra: str


def run_iptables() -> str:
    result = subprocess.run(
        ["iptables", "-L", "-v", "-n", "-x"],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def parse_metrics(raw: str) -> list[RuleMetric]:
    metrics: list[RuleMetric] = []
    chain = "unknown"
    for line in raw.splitlines():
        if line.startswith("Chain "):
            chain = line.split()[1]
            continue
        match = RULE_PATTERN.match(line)
        if not match:
            continue
        metrics.append(
            RuleMetric(
                chain=chain,
                packets=int(match.group("pkts")),
                bytes=int(match.group("bytes")),
                target=match.group("target"),
                proto=match.group("proto"),
                in_iface=match.group("in"),
                out_iface=match.group("out"),
                source=match.group("src"),
                destination=match.group("dst"),
                extra=match.group("extra").strip(),
            )
        )
    return metrics


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="Emit JSON")
    args = parser.parse_args()

    metrics = parse_metrics(run_iptables())

    if args.json:
        print(json.dumps([asdict(metric) for metric in metrics], indent=2))
        return

    for metric in metrics:
        print(
            f"{metric.chain:12} pkts={metric.packets:<8} bytes={metric.bytes:<10} "
            f"target={metric.target:<10} proto={metric.proto:<4} "
            f"{metric.source} -> {metric.destination} {metric.extra}"
        )


if __name__ == "__main__":
    main()
