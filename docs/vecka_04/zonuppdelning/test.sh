#!/usr/bin/env bash
# Läser testfall.csv och kör de testfall vars källa är den här servern.
# Skriver faktiskt utfall per rad och sparar resultatet som testprotokoll-<server>-<tid>.csv.
# Utfall: oppen (svar), avvisad (RST eller ICMP-fel, snabbt nej), tyst (inget svar före timeout).
# Användning: ./test.sh [testfall.csv]
fil="${1:-testfall.csv}"
jag="$(hostname -s)"
ut="testprotokoll-${jag}-$(date -u +%Y%m%dT%H%M%SZ).csv"

prova_tcp() {   # $1 = adress, $2 = port
    timeout 3 bash -c "exec 3<>/dev/tcp/$1/$2" 2>/dev/null
    case $? in
        0)   echo oppen ;;
        124) echo tyst ;;      # timeout avbröt – inget svar
        *)   echo avvisad ;;   # snabbt nej: RST eller ICMP-fel
    esac
}

prova_dns() {   # $1 = resolver
    svar=$(dig +time=3 +tries=1 @"$1" log.sec.chas-lab.dev A 2>&1)
    if   [ $? -eq 0 ];                          then echo oppen
    elif grep -qi "refused\|unreachable" <<<"$svar"; then echo avvisad
    else                                             echo tyst
    fi
}

prova_ntp() {   # $1 = NTP-server
    python3 - "$1" <<'EOF'
import socket, sys
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.settimeout(3)
try:
    s.connect((sys.argv[1], 123))
    s.send(b"\x1b" + 47 * b"\0")      # NTP-klientfråga (version 3, läge 3)
    s.recv(48)
    print("oppen")
except socket.timeout:
    print("tyst")
except OSError:
    print("avvisad")
EOF
}

prova_icmp() {  # $1 = adress
    svar=$(ping -c 1 -W 3 "$1" 2>&1)
    if   [ $? -eq 0 ];                                   then echo oppen
    elif grep -qi "unreachable\|prohibited" <<<"$svar"; then echo avvisad
    else                                                      echo tyst
    fi
}

echo "id,kalla,destination,port,protokoll,riktning,forvantat,faktiskt,tid_ms,resultat" | tee "$ut"
tail -n +2 "$fil" | while IFS=, read -r id kalla dest port proto riktn forv _; do
    [ "$kalla" = "$jag" ] || continue
    start=$(date +%s%N)
    case "$proto/$port" in
        tcp/*)  utfall=$(prova_tcp "$dest" "$port") ;;
        udp/53) utfall=$(prova_dns "$dest") ;;
        udp/123) utfall=$(prova_ntp "$dest") ;;
        icmp/*) utfall=$(prova_icmp "$dest") ;;
        *)      utfall=okant ;;
    esac
    ms=$(( ($(date +%s%N) - start) / 1000000 ))
    [ "$utfall" = "$forv" ] && res=OK || res=AVVIKER
    echo "$id,$kalla,$dest,$port,$proto,$riktn,$forv,$utfall,$ms,$res" | tee -a "$ut"
done
echo "Sparat: $ut" >&2
