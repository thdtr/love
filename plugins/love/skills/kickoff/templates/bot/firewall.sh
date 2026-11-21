#!/usr/bin/env bash
# Blocks all outbound traffic except DNS and the hosts below.
set -euo pipefail

hosts=(
  api.anthropic.com
  claude.ai
  # <package registries for the project's stacks>
)

ipset create allowed hash:net -exist
ipset flush allowed

for range in $(curl -fsS https://api.github.com/meta | jq -r '(.web + .api + .git)[]' | grep -v ':'); do
  ipset add allowed "$range" -exist
done
for host in "${hosts[@]}"; do
  for ip in $(dig +short A "$host" | grep -E '^[0-9.]+$'); do
    ipset add allowed "$ip" -exist
  done
done

iptables -F OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m set --match-set allowed dst -j ACCEPT
iptables -P OUTPUT DROP

if curl -fsS --max-time 5 https://example.com >/dev/null 2>&1; then
  echo "firewall check failed, example.com is reachable" >&2
  exit 1
fi
