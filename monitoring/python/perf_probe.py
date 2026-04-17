#!/usr/bin/env python3
"""Simple latency and reachability probe for OpenWrt."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from statistics import mean


PING_RE = re.compile(r"time=(?P<latency>[0-9.]+)")


def ping_target(target: str, count: int) -> tuple[bool, list[float]]:
    result = subprocess.run(
        ["ping", "-c", str(count), "-W", "2", target],
        capture_output=True,
        text=True,
    )
    latencies = [float(match.group("latency")) for match in PING_RE.finditer(result.stdout)]
    return result.returncode == 0, latencies


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--targets", nargs="+", required=True, help="Targets to probe")
    parser.add_argument("--count", type=int, default=4, help="ICMP echo count")
    args = parser.parse_args()

    overall_ok = True
    for target in args.targets:
        success, latencies = ping_target(target, args.count)
        if success and latencies:
            print(f"{target}: reachable avg_ms={mean(latencies):.2f} samples={len(latencies)}")
        else:
            overall_ok = False
            print(f"{target}: unreachable")

    return 0 if overall_ok else 1


if __name__ == "__main__":
    sys.exit(main())
