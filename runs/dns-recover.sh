#!/usr/bin/env bash
# Emergency DNS / internet recovery for porn-block.sh.
# Undoes the DNS *enforcement* (forced-1.1.1.3 redirect + immutable locks) so the
# network resolves normally again. Leaves the /etc/hosts blocklist content intact
# (that list only blocks specific porn domains and never breaks general internet).

set -uo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

if [ "$EUID" -ne 0 ]; then
    err "Run as root: sudo bash $0"
    exit 1
fi

WLAN_CONF="/etc/systemd/network/20-wlan.network"
RESOLVED_BLOCK_CONF="/etc/systemd/resolved.conf.d/zz-porn-block-fast-dns.conf"
OLD_RESOLVED_BLOCK_CONF="/etc/systemd/resolved.conf.d/99-porn-block-fast-dns.conf"

# 1. Unlock the immutable files
chattr -i "$WLAN_CONF" /etc/hosts 2>/dev/null || true
ok "Unlocked $WLAN_CONF and /etc/hosts"

rm -f "$RESOLVED_BLOCK_CONF" "$OLD_RESOLVED_BLOCK_CONF"
ok "Removed porn-block resolved override"

# 2. Remove the forced-DNS iptables redirect (every variant this setup uses)
for proto in udp tcp; do
    iptables -t nat -D OUTPUT -p "$proto" --dport 53 ! -d 1.1.1.3 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null || true
    iptables -t nat -D OUTPUT -p "$proto" --dport 53 ! -d 127.0.0.0/8 ! -d 1.1.1.3 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null || true
    iptables -t nat -D OUTPUT -p "$proto" --dport 53 -d 127.0.0.0/8 -j RETURN 2>/dev/null || true
    iptables -t nat -D OUTPUT -p "$proto" --dport 53 -d 1.1.1.3 -j RETURN 2>/dev/null || true
    iptables -t nat -D OUTPUT -p "$proto" --dport 53 -j DNAT --to-destination 1.1.1.3:53 2>/dev/null || true
done
mkdir -p /etc/iptables
iptables-save > /etc/iptables/iptables.rules
ok "Removed DNS redirect rules"

# 3. Restart networking and wait for it to settle
systemctl restart systemd-networkd systemd-resolved
ok "Restarted networkd + resolved"

echo -n "Waiting for DNS"
RESOLVED=0
for _ in $(seq 1 15); do
    if getent hosts github.com >/dev/null 2>&1; then RESOLVED=1; break; fi
    echo -n "."; sleep 1
done
echo

# 4. If still broken, force a known-good resolver on the wifi link (runtime only)
if [ "$RESOLVED" -ne 1 ]; then
    warn "Configured DNS still not resolving — applying runtime fallback (1.1.1.1 / 8.8.8.8) on wlan0"
    resolvectl dns wlan0 1.1.1.1 8.8.8.8 2>/dev/null || true
    resolvectl flush-caches 2>/dev/null || true
    getent hosts github.com >/dev/null 2>&1 && RESOLVED=1
fi

# 5. Report
echo ""
if [ "$RESOLVED" -eq 1 ]; then
    ok "Internet/DNS restored — github.com resolves."
    echo "    Your porn /etc/hosts blocks are still active. DNS enforcement is OFF;"
    echo "    re-run porn-block.sh (now hardened) when you want it back."
else
    err "DNS still failing. Check manually:"
    echo "      resolvectl status"
    echo "      ping -c1 1.1.1.1     # network up?"
    echo "      ping -c1 1.1.1.3     # is Cloudflare-Families reachable on this wifi?"
fi
