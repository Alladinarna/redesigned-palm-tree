#!/usr/bin/env bash
# Laddar den egna serverns regelverk (<server>/<server>-zon.nft) som /etc/nftables/zon.nft med säkerhetsnät.
# Körs från zonuppdelning-mappen på den egna servern:  sudo bash ladda-zon.sh
set -euo pipefail
jag="$(hostname -s)"
src="$(cd "$(dirname "$0")" && pwd)/$jag/$jag-zon.nft"
[ -f "$src" ] || { echo "Hittar inte $src" >&2; exit 1; }

echo "== Nuvarande /etc/sysconfig/nftables.conf (utan kommentarer)"
grep -v '^\s*#' /etc/sysconfig/nftables.conf | sed '/^\s*$/d' || true

nft -c -f "$src"
[ -f /etc/nftables/zon.nft ] && cp /etc/nftables/zon.nft "/etc/nftables/zon.nft.bak-$(date +%Y%m%d%H%M)"
install -m 0644 "$src" /etc/nftables/zon.nft
grep -q 'include "/etc/nftables/zon.nft"' /etc/sysconfig/nftables.conf \
  || echo 'include "/etc/nftables/zon.nft"' >> /etc/sysconfig/nftables.conf

systemd-run --on-active=5min --unit=nodbroms nft flush ruleset
nft -f /etc/nftables/zon.nft
systemctl enable nftables >/dev/null
echo
echo "== Laddat $src."
echo "   Säkerhetsnätet TÖMMER regelverket om 5 min om du inte stoppar det."
echo "   Öppna en NY session via jump. Fungerar den: sudo systemctl stop nodbroms.timer"
