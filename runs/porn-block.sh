#!/usr/bin/env bash
# porn-block — one script, two machines.
#
#   arch : laptop  — systemd-networkd + systemd-resolved, wlan0
#   omen : karserver (Ubuntu) — NetworkManager (via netplan) + systemd-resolved, wlo1
#
# The profile is detected from the running network stack and can be forced.
# Style follows ../run.sh: `--dry` prints every action without doing it.
#
#   bash runs/porn-block.sh --dry             # preview, no root needed
#   sudo bash runs/porn-block.sh              # apply, auto-detected profile
#   sudo bash runs/porn-block.sh --profile omen

set -uo pipefail

script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Initialize variables
dry="0"      # Use "1" for true (dry run enabled), "0" for false (execute)
profile=""   # "arch" | "omen"; empty means auto-detect

orig_args=("$@")

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry)
            dry="1"
            ;;
        --profile)
            shift
            profile="${1:-}"
            ;;
        --profile=*)
            profile="${1#*=}"
            ;;
        *)
            echo "Usage: $0 [--dry] [--profile arch|omen]"
            exit 1
            ;;
    esac
    shift
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }

# --- Logging Function ---
log() {
    if [[ "$dry" == "1" ]]; then
        echo "[DRY_RUN]: $1"
    else
        echo "$1"
    fi
}

# --- Execution Function ---
# Executes commands (or shell functions) passed as arguments, unless dry run.
execute() {
    log "Executing: \"$*\""

    if [[ "$dry" == "1" ]]; then
        log "(Skipped execution due to dry run)"
        return 0
    fi

    "$@"
    return $?
}

# --- Step Helper ---
# execute() plus a success message that only prints when work really happened.
step() {
    local msg="$1"; shift
    execute "$@" || return $?
    [[ "$dry" == "0" ]] && ok "$msg"
    return 0
}

# --- Preconditions ---
# This script is picked up by ../run.sh, which runs everything unprivileged.
# Re-exec through sudo instead of failing so a plain `./run.sh` still applies it.
if [[ "$dry" == "0" && "$EUID" -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        log "Not root — re-running through sudo"
        exec sudo -- bash "$0" "${orig_args[@]+"${orig_args[@]}"}"
    fi
    err "Run as root: sudo bash $0"
    exit 1
fi

# --- Profile Detection ---
# The distro is the reliable discriminator. NetworkManager is present on both
# boxes (Omarchy ships it too), so it cannot be used to tell them apart.
detect_profile() {
    local id=""
    [[ -r /etc/os-release ]] && id="$(. /etc/os-release; echo "${ID:-}")"
    case "$id" in
        arch|archarm|cachyos|endeavouros|manjaro) echo "arch" ;;
        ubuntu|debian|pop|linuxmint)              echo "omen" ;;
        *)
            # Unknown distro: fall back to which resolver config actually exists.
            if [[ -d /etc/netplan ]]; then echo "omen"; else echo "arch"; fi
            ;;
    esac
}

[[ -z "$profile" ]] && profile="$(detect_profile)"

case "$profile" in
    arch|omen) ;;
    *) err "Unknown profile: $profile (expected arch or omen)"; exit 1 ;;
esac

DNS4_1="1.1.1.3"; DNS4_2="1.0.0.3"
DNS6_1="2606:4700:4700::1113"; DNS6_2="2606:4700:4700::1003"

if [[ "$profile" == "arch" ]]; then
    IFACE="wlan0"
    WLAN_CONF="/etc/systemd/network/20-wlan.network"
    RESOLVED_CONF="/etc/systemd/resolved.conf.d/zz-porn-block-fast-dns.conf"
    OLD_RESOLVED_CONF="/etc/systemd/resolved.conf.d/99-porn-block-fast-dns.conf"
    LOCKED_NET_FILE="$WLAN_CONF"
else
    IFACE="wlo1"
    NM_CONN="Airtel_Veera"
    # Ubuntu renders NM connections through netplan, so the on-disk source of
    # truth is the netplan yaml, NOT /etc/NetworkManager/system-connections.
    NM_KEYFILE="$(grep -l "$NM_CONN" /etc/netplan/*.yaml 2>/dev/null | head -1)"
    NM_KEYFILE="${NM_KEYFILE:-/etc/netplan/nonexistent}"
    RESOLVED_CONF="/etc/systemd/resolved.conf.d/zz-porn-block.conf"
    LOCKED_NET_FILE="$NM_KEYFILE"
fi

HOSTNAME_SHORT="$(hostname)"

log "Script directory: $script_dir"
log "Profile: $profile (interface $IFACE)"
log "Dry run enabled: $dry"

# ── 1. DNS: Cloudflare for Families ──────────────────────────────────────────
# arch: written into the networkd link file, which is then made immutable.
# Keep it idempotent — older runs may have inserted duplicate DNS/UseDNS lines.
pin_networkd_dns() {
    sed -i "/^DNS=${DNS4_1} ${DNS4_2}\$/d" "$WLAN_CONF"
    sed -i '/^UseDNS=false$/d' "$WLAN_CONF"
    sed -i "/^MulticastDNS=yes/a DNS=${DNS4_1} ${DNS4_2}" "$WLAN_CONF"
    sed -i '/^\[DHCPv4\]/a UseDNS=false' "$WLAN_CONF"
}

# omen: pinned on the NM connection, IPv6 included — the router hands out
# fe80::1 as a v6 resolver and that path must not stay open.
pin_nm_dns() {
    nmcli connection modify "$NM_CONN" \
        ipv4.dns "${DNS4_1},${DNS4_2}" \
        ipv4.ignore-auto-dns yes \
        ipv6.dns "${DNS6_1},${DNS6_2}" \
        ipv6.ignore-auto-dns yes \
        && ok "NM: pinned ${DNS4_1}/${DNS4_2} on $NM_CONN, ignoring DHCP/RA DNS" \
        || warn "nmcli modify failed"
}

# Global resolved defaults. On arch this also undoes any Omarchy/local config
# that turns on strict DNS-over-TLS: that is slower and breaks link DNS like
# 1.1.1.3 because no TLS hostname is set. On omen it additionally covers links
# NM does not manage (wg0, docker bridges).
write_resolved_conf() {
    mkdir -p /etc/systemd/resolved.conf.d
    [[ "$profile" == "arch" ]] && rm -f "$OLD_RESOLVED_CONF"
    if [[ "$profile" == "arch" ]]; then
        cat > "$RESOLVED_CONF" <<EOF
[Resolve]
DNS=${DNS4_1} ${DNS4_2}
FallbackDNS=1.1.1.1 8.8.8.8
DNSOverTLS=no
Cache=yes
EOF
    else
        cat > "$RESOLVED_CONF" <<EOF
[Resolve]
DNS=${DNS4_1} ${DNS4_2}
FallbackDNS=${DNS4_1} ${DNS4_2}
DNSOverTLS=no
DNSStubListener=yes
Cache=yes
EOF
    fi
}

# omen only: apply to the live link WITHOUT bouncing wifi, so an SSH session
# into the box survives the run.
apply_live_dns() {
    resolvectl dns "$IFACE" "$DNS4_1" "$DNS4_2" "$DNS6_1" "$DNS6_2" 2>/dev/null \
        && ok "Applied DNS to $IFACE live (no link bounce)" \
        || warn "resolvectl dns failed on $IFACE"
    resolvectl domain "$IFACE" "~." 2>/dev/null || true
    resolvectl flush-caches 2>/dev/null || true
}

lock_net_file() {
    chattr +i "$LOCKED_NET_FILE" 2>/dev/null && ok "Locked $LOCKED_NET_FILE (immutable)" \
        || warn "Could not lock $LOCKED_NET_FILE"
}

# Wait for DNS to come back (on arch the wifi link reassociates after restart).
wait_for_dns() {
    echo -n "Waiting for DNS"
    for _ in $(seq 1 15); do
        resolvectl query raw.githubusercontent.com >/dev/null 2>&1 && break
        echo -n "."; sleep 1
    done
    echo
}

log "--- 1. Pinning DNS to Cloudflare for Families ---"
execute chattr -i "$LOCKED_NET_FILE" 2>/dev/null || true

if [[ "$profile" == "arch" ]]; then
    step "Set $IFACE DNS to ${DNS4_1} / ${DNS4_2} (Cloudflare for Families)" pin_networkd_dns
else
    execute pin_nm_dns
fi

step "systemd-resolved: global DNS pinned to Cloudflare for Families" write_resolved_conf
step "/etc/resolv.conf -> systemd-resolved stub" ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

if [[ "$profile" == "arch" ]]; then
    execute lock_net_file
    step "Restarted systemd-networkd and systemd-resolved" systemctl restart systemd-networkd systemd-resolved
else
    execute systemctl restart systemd-resolved
    execute apply_live_dns
    execute lock_net_file
fi

execute wait_for_dns

# ── 2. /etc/hosts — StevenBlack porn blocklist ───────────────────────────────
backup_hosts() {
    cp -a /etc/hosts "/root/hosts.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
}

install_stevenblack_hosts() {
    echo "Downloading StevenBlack hosts (porn filter)..."
    if curl -fsSL --retry 5 --retry-delay 3 --retry-connrefused \
        "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts" \
        -o /tmp/stevenblack-hosts && [ -s /tmp/stevenblack-hosts ]; then
        cat /tmp/stevenblack-hosts > /etc/hosts
        ok "Installed StevenBlack hosts ($(grep -c '^0.0.0.0' /etc/hosts) entries)"
    else
        warn "StevenBlack download failed (offline/DNS) — keeping existing /etc/hosts, extras only"
    fi
}

# The StevenBlack file carries no local entries. Without 127.0.0.1 (both boxes)
# and 127.0.1.1 (omen, where sudo/hostname lookups stall without it) the machine
# is left in a bad state.
restore_local_hostnames() {
    if [[ "$profile" == "omen" ]]; then
        grep -q "^127.0.1.1[[:space:]]" /etc/hosts 2>/dev/null || \
            sed -i "1i 127.0.1.1\t${HOSTNAME_SHORT}" /etc/hosts
    fi
    grep -q "^127.0.0.1[[:space:]]" /etc/hosts 2>/dev/null || \
        sed -i "1i 127.0.0.1\tlocalhost" /etc/hosts
    grep -q "^::1[[:space:]]" /etc/hosts 2>/dev/null || \
        sed -i "2i ::1\tlocalhost" /etc/hosts
}

log "--- 2. Installing /etc/hosts blocklist ---"
execute chattr -i /etc/hosts 2>/dev/null || true
execute backup_hosts
execute install_stevenblack_hosts
step "Preserved localhost / ${HOSTNAME_SHORT} entries" restore_local_hostnames

# ── 2a. Whitelist — strip these domains from the StevenBlack list ────────────
WHITELIST_SITES=(
    "mixpanel.com"
)

apply_whitelist() {
    for site in "${WHITELIST_SITES[@]}"; do
        sed -i -E "/^0\.0\.0\.0[[:space:]]+([a-zA-Z0-9-]+\.)*${site//./\\.}$/d" /etc/hosts
        sed -i -E "/^#[[:space:]]*\[${site//./\\.}\]$/d" /etc/hosts
    done
}

step "Whitelisted ${#WHITELIST_SITES[@]} domain(s)" apply_whitelist

# ── 2b. Force-allow (arch only) ──────────────────────────────────────────────
# Cloudflare for Families blocks these at DNS level; /etc/hosts takes precedence
# over DNS, so pinning the real IP bypasses the filter for specific sites.
# omen is locked down — there these are blocked with everything else instead.
FORCE_ALLOW_SITES=(
    "kissanime.com.ru"
    "kaa.lt"
    "animixplay.com.se"
)

apply_force_allow() {
    for site in "${FORCE_ALLOW_SITES[@]}"; do
        sed -i -E "/^0\.0\.0\.0[[:space:]]+([a-zA-Z0-9-]+\.)*${site//./\\.}$/d" /etc/hosts
        # Use DoH via IP (port 443) to bypass the iptables port-53 redirect.
        # Connecting to 1.1.1.1 by IP also bypasses /etc/hosts hostname blocks.
        real_ip=$(curl -s --max-time 5 \
            "https://1.1.1.1/dns-query?name=${site}&type=A" \
            -H "accept: application/dns-json" 2>/dev/null \
            | grep -oP '"data":"\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$real_ip" ] && [ "$real_ip" != "0.0.0.0" ]; then
            grep -q "^$real_ip $site$" /etc/hosts || echo "$real_ip $site" >> /etc/hosts
            grep -q "^$real_ip www.$site$" /etc/hosts || echo "$real_ip www.$site" >> /etc/hosts
            ok "Force-allowed $site -> $real_ip"
        else
            warn "Could not resolve $site via DoH — may still be filtered"
        fi
    done
}

# ── 3. Extra grey / missed sites ─────────────────────────────────────────────
EXTRA_SITES=(
    "yiff.party"
    "imhentai.com"
    "newgrounds.com"
    "furaffinity.net"
    "zerochan.net"
    "safebooru.org"
    "8kun.top"
    "javhd.com"
    "javmost.com"
    "jav.guru"
    "r34.app"
    "hentai-foundry.com"
    "shadbase.com"
    "toongod.org"
    "webtoonscans.com"
    "toonily.me"
    "toonily.com"
    "manhwa-raw.com"
    "manhwaread.com"
    "manhwabuddy.com"
    "hentai20.io"
    "seedr.cc"
    "piratebayproxy.net"
    "webtoon.xyz"
    "bet365.com"
    "free3dadultgames.com"
    "torrentg1.net"
    "watchmygirlfriend.tv"

    # ── Manga / Manhwa readers (all blocked except asuracomic.net) ──
    # Manga
    "natomanga.com"
    "mangadex.org"
    "mangakakalot.com"
    "mangakakalot.gg"
    "manganato.com"
    "manganelo.com"
    "chapmanganato.to"
    "nelomanga.com"
    "fanfox.net"
    "mangafox.me"
    "mangapark.net"
    "mangapark.io"
    "mangareader.to"
    "mangabuddy.com"
    "mangahere.cc"
    "mangafreak.net"
    "mangago.me"
    "comick.io"
    "bato.to"
    "mangasee123.com"
    "manga4life.com"
    "mangatx.com"
    "mangaclash.com"
    "mangakomi.io"
    "mangaowl.to"
    "mangapill.com"
    "mangahasu.se"
    "readm.org"
    "mangainn.net"
    "mangahub.io"
    "mangakatana.com"
    "mangabat.com"
    "mangaforfree.com"
    "weebcentral.com"
    # Manhwa
    "manhuaplus.com"
    "flamecomics.com"
    "flamescans.org"
    "reaperscans.com"
    "realmscans.to"
    "manhwaclan.com"
    "manhwaclan.co.uk"
    "1stkissmanga.me"
    "topmanhua.com"
    "manytoon.com"
    "manhwatop.com"
    "manhuaus.com"
    "zinmanga.com"
    "aquamanga.com"
    "kunmanga.com"
    "mangaweebs.in"
    "harimanga.com"
    "coffeemanga.io"
    "manhuafast.com"
    "drakescans.com"
    "voidscans.net"
    "luminousscans.com"
    "demonicscans.org"
    "isekaiscan.com"
    "manhwafull.net"
    "toonkor.com"
    "webtoons.com"

    # ── More aggregators + scanlation groups + 18+ manhwa/hentai (batch 2) ──
    "manhwahub.net"
    "mangafire.to"
    "likemanga.io"
    "mgeko.cc"
    "mangageko.com"
    "rawkuma.com"
    "manhuascan.us"
    "manhuabox.net"
    "manhuaga.com"
    "mangakik.com"
    "mangagalaxy.me"
    "mangaowls.com"
    "manhwaz.com"
    "manhwazone.to"
    "comicextra.com"
    "readcomiconline.li"
    # Scanlation groups
    "zeroscans.com"
    "leviatanscans.com"
    "lscomic.com"
    "cosmicscans.com"
    "nightscans.org"
    "arvenscans.org"
    "suryascans.com"
    "infernalvoidscans.com"
    "setsuscans.com"
    "drakecomic.org"
    "resetscans.com"
    "hivetoon.com"
    # 18+ / adult manhwa & hentai
    "manhwa18.com"
    "manhwa18.cc"
    "manhwa18.net"
    "manhwahentai.me"
    "readmanhwa.com"
    "hiperdex.com"
    "manga18fx.com"
    "mangadistrict.com"
    "pornwha.com"
    "toonily.net"
    "omegascans.org"
    "hentai2read.com"
    "hentaihere.com"
    "hentairead.com"
    "tsumino.com"
    "pururin.to"
    "8muses.com"
    "luscious.net"
    "e-hentai.org"
    "exhentai.org"
    "nhentai.to"
    "simply-hentai.com"
    "fakku.net"
    "hentaifox.com"
    "multporn.net"
    # Official platforms with 18+ catalogs
    "toomics.com"
    "toptoon.com"
    "lezhin.com"
    "tapas.io"
    "tappytoon.com"

    # ── DoH (DNS-over-HTTPS) endpoints ──
    # Browsers use these to bypass /etc/hosts and the OS resolver. Block the
    # hostnames so the TLS handshake fails and they fall back to system DNS.
    "mozilla.cloudflare-dns.com"
    "chrome.cloudflare-dns.com"
    "cloudflare-dns.com"
    "dns.google"
    "dns.google.com"
    "dns.quad9.net"
    "dns9.quad9.net"
    "dns.nextdns.io"
    "doh.opendns.com"
    "doh.cleanbrowsing.org"
    "doh.dns.sb"
    "doh.libredns.gr"
    "doh.powerdns.org"
    "dns.adguard.com"
    "dns.adguard-dns.com"
    "doh.familyshield.opendns.com"
)

# On omen nothing is punched through, so the force-allow list is blocked too.
if [[ "$profile" == "omen" ]]; then
    EXTRA_SITES+=( "${FORCE_ALLOW_SITES[@]}" )
fi

append_extra_sites() {
    echo "" >> /etc/hosts
    echo "# Extra blocks" >> /etc/hosts
    for site in "${EXTRA_SITES[@]}"; do
        if ! grep -q "0\.0\.0\.0 ${site}$" /etc/hosts; then
            echo "0.0.0.0 ${site}" >> /etc/hosts
            echo "0.0.0.0 www.${site}" >> /etc/hosts
        fi
    done
}

dedupe_hosts() {
    awk '!seen[$0]++' /etc/hosts > /tmp/hosts-clean && mv /tmp/hosts-clean /etc/hosts
    chown root:root /etc/hosts; chmod 644 /etc/hosts
    ok "Deduplicated /etc/hosts ($(wc -l < /etc/hosts) lines total)"
}

log "--- 3. Adding extra blocks ---"
step "Added ${#EXTRA_SITES[@]} extra sites to /etc/hosts" append_extra_sites
[[ "$profile" == "arch" ]] && execute apply_force_allow
execute dedupe_hosts
step "Locked /etc/hosts (immutable)" chattr +i /etc/hosts

# ── 4. iptables — force DNS through Cloudflare for Families ─────────────────
# OUTPUT covers host-local traffic. Keep localhost stubs and direct Families
# queries untouched, then redirect every other port-53 query. nft-backed
# iptables rejects rules with multiple negated destinations, so use early
# RETURN rules instead of `! -d`.
apply_iptables_output() {
    for proto in udp tcp; do
        iptables -t nat -D OUTPUT -p "$proto" --dport 53 ! -d "$DNS4_1" -j DNAT --to-destination "$DNS4_1:53" 2>/dev/null || true
        iptables -t nat -D OUTPUT -p "$proto" --dport 53 ! -d 127.0.0.0/8 ! -d "$DNS4_1" -j DNAT --to-destination "$DNS4_1:53" 2>/dev/null || true
        iptables -t nat -D OUTPUT -p "$proto" --dport 53 -d 127.0.0.0/8 -j RETURN 2>/dev/null || true
        iptables -t nat -D OUTPUT -p "$proto" --dport 53 -d "$DNS4_1" -j RETURN 2>/dev/null || true
        iptables -t nat -D OUTPUT -p "$proto" --dport 53 -j DNAT --to-destination "$DNS4_1:53" 2>/dev/null || true

        iptables -t nat -A OUTPUT -p "$proto" --dport 53 -d 127.0.0.0/8 -j RETURN
        iptables -t nat -A OUTPUT -p "$proto" --dport 53 -d "$DNS4_1" -j RETURN
        iptables -t nat -A OUTPUT -p "$proto" --dport 53 -j DNAT --to-destination "$DNS4_1:53"
    done
}

# omen only: PREROUTING covers forwarded traffic from the docker bridges and
# wg0 clients, which OUTPUT never sees.
apply_iptables_forwarded() {
    for proto in udp tcp; do
        iptables -t nat -D PREROUTING -p "$proto" --dport 53 -d "$DNS4_1" -j RETURN 2>/dev/null || true
        iptables -t nat -D PREROUTING -p "$proto" --dport 53 -j DNAT --to-destination "$DNS4_1:53" 2>/dev/null || true

        iptables -t nat -A PREROUTING -p "$proto" --dport 53 -d "$DNS4_1" -j RETURN
        iptables -t nat -A PREROUTING -p "$proto" --dport 53 -j DNAT --to-destination "$DNS4_1:53"
    done
}

# omen only: the router advertises fe80::1 as a resolver — reject any v6 DNS
# not aimed at Cloudflare Families so resolution falls back to the pinned v4.
#
# These MUST be inserted at the top of filter OUTPUT, not appended: ufw is
# active there and `ufw-track-output` ACCEPTs NEW connections, which is
# terminal — any rule appended after ufw's jumps is never reached.
apply_ip6tables() {
    for proto in udp tcp; do
        ip6tables -t filter -D OUTPUT -p "$proto" --dport 53 -d "$DNS6_1" -j ACCEPT 2>/dev/null || true
        ip6tables -t filter -D OUTPUT -p "$proto" --dport 53 -d "$DNS6_2" -j ACCEPT 2>/dev/null || true
        ip6tables -t filter -D OUTPUT -p "$proto" --dport 53 -d ::1 -j ACCEPT 2>/dev/null || true
        ip6tables -t filter -D OUTPUT -p "$proto" --dport 53 -j REJECT 2>/dev/null || true

        # Reverse order — each -I 1 pushes the previous rule down.
        ip6tables -t filter -I OUTPUT 1 -p "$proto" --dport 53 -j REJECT
        ip6tables -t filter -I OUTPUT 1 -p "$proto" --dport 53 -d "$DNS6_2" -j ACCEPT
        ip6tables -t filter -I OUTPUT 1 -p "$proto" --dport 53 -d "$DNS6_1" -j ACCEPT
        ip6tables -t filter -I OUTPUT 1 -p "$proto" --dport 53 -d ::1 -j ACCEPT
    done
}

# omen only: block DoT (853) outright — encrypted DNS to anywhere but our
# resolver. Same ufw caveat: insert at the top, never append.
block_dot() {
    iptables -D OUTPUT -p tcp --dport 853 -j REJECT 2>/dev/null || true
    iptables -I OUTPUT 1 -p tcp --dport 853 -j REJECT
    ip6tables -D OUTPUT -p tcp --dport 853 -j REJECT 2>/dev/null || true
    ip6tables -I OUTPUT 1 -p tcp --dport 853 -j REJECT
}

# arch: the distro ships an iptables.service that restores /etc/iptables.
# omen: no iptables-persistent package, so carry our own restore unit.
persist_iptables() {
    mkdir -p /etc/iptables
    if [[ "$profile" == "arch" ]]; then
        iptables-save > /etc/iptables/iptables.rules
        systemctl enable --now iptables 2>/dev/null \
            || warn "iptables service not found — rules saved but may not persist on reboot"
        ok "iptables rules saved"
        return 0
    fi

    iptables-save  > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6
    cat > /etc/systemd/system/porn-block-iptables.service <<'EOF'
[Unit]
Description=Restore porn-block iptables rules
After=network-pre.target
Before=network.target
DefaultDependencies=no

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c '/sbin/iptables-restore < /etc/iptables/rules.v4; /sbin/ip6tables-restore < /etc/iptables/rules.v6'

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable porn-block-iptables.service >/dev/null 2>&1 \
        && ok "Rules persisted via porn-block-iptables.service" \
        || warn "Could not enable persistence unit"
}

log "--- 4. Forcing DNS through ${DNS4_1} ---"
step "iptables: host DNS forced through ${DNS4_1} (localhost exempt)" apply_iptables_output
if [[ "$profile" == "omen" ]]; then
    step "iptables: forwarded DNS (containers, wg0 peers) forced through ${DNS4_1}" apply_iptables_forwarded
    step "ip6tables: IPv6 DNS restricted to Cloudflare for Families" apply_ip6tables
    step "Blocked DNS-over-TLS (tcp/853)" block_dot
fi
execute persist_iptables

# ── 5. Verification ──────────────────────────────────────────────────────────
verify() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Verification ($profile)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "Active DNS ($IFACE): $(resolvectl status "$IFACE" 2>/dev/null | grep 'Current DNS Server' | awk '{print $NF}')"
    echo -n "DNS stub (127.0.0.53): "
    resolvectl query google.com &>/dev/null && echo "working" || echo "BROKEN"

    local TEST_SITES=(pornhub.com xvideos.com nhentai.net hanime.tv yiff.party imhentai.com newgrounds.com)
    [[ "$profile" == "omen" ]] && TEST_SITES+=(kaa.lt)
    local FAIL=0

    for site in "${TEST_SITES[@]}"; do
        result=$(dig +short +time=3 +tries=1 "$site" @"$DNS4_1" 2>/dev/null | head -1)
        in_hosts=$(grep -cE "^0\.0\.0\.0[[:space:]]+${site//./\\.}$" /etc/hosts 2>/dev/null || echo 0)
        if [ "$result" = "0.0.0.0" ] || [ -z "$result" ] || [ "$in_hosts" -gt 0 ]; then
            ok "blocked: $site"
        else
            err "NOT blocked: $site -> $result"
            FAIL=$((FAIL+1))
        fi
    done

    echo ""
    echo "Hosts entries : $(grep -c '^0.0.0.0' /etc/hosts)"
    echo "Immutable     : $(lsattr /etc/hosts | awk '{print $1}') /etc/hosts"
    echo "Immutable     : $(lsattr "$LOCKED_NET_FILE" 2>/dev/null | awk '{print $1}') $LOCKED_NET_FILE"
    echo ""
    [ "$FAIL" -eq 0 ] && ok "All checks passed." || warn "$FAIL site(s) not blocked."
}

log "--- 5. Verification ---"
execute verify

log "porn-block finished ($profile)."
