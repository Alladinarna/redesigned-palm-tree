#!/usr/bin/env bash
# Sätter upp loggkedjan till log över TLS på den egna servern (milstolpe 5).
# Ordning enligt studieguiden: tid först, flöde sedan, vidarebefordran därefter, testhändelse sist.
# Kräver att regelverket med D5 på tcp/6514 redan är laddat (sudo bash ladda-zon.sh i vecka_04/zonuppdelning).
# Körs från logginsamling-mappen på den egna servern:  sudo bash ladda-logg.sh
set -euo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
LOG=172.20.1.58
LOGNAMN=log.sec.chas-lab.dev
# Fingeravtrycket kontrollerat 2/11 mot http://log.sec.chas-lab.dev/ca.pem (hämtat via jump), CN=ITSX26 labb-CA
CA_SHA256="2A:B7:EE:ED:0D:65:45:12:D9:51:0A:CF:4E:FA:15:1B:F5:DC:4E:B4:8E:C9:E0:B9:20:59:C1:C8:3B:A6:0C:53"

[ "$(id -u)" -eq 0 ] || { echo "Kör med sudo" >&2; exit 1; }

echo "== 1. Tid"
chronyc tracking | grep -E 'Reference|System time|Leap'
timedatectl | grep -E 'Time zone|synchronized'
chronyc tracking | grep -q 'Leap status *: Normal' \
  || { echo "Klockan är inte synkad. Fixa tiden (D4) innan loggarna skickas." >&2; exit 1; }

echo "== 2. Flödet: släpper regelverket tcp/6514 mot log?"
nft list ruleset | grep -q "ip daddr $LOG tcp dport 6514 accept" \
  || { echo "D5 på tcp/6514 saknas. Ladda regelverket med ladda-zon.sh först." >&2; exit 1; }

echo "== 3. Paket (TLS-stöd till rsyslog och auditd:s syslog-plugin)"
dnf install -y -q rsyslog-gnutls audispd-plugins

echo "== 4. CA-certifikatet"
fp="$(openssl x509 -in "$dir/ca.pem" -noout -fingerprint -sha256 | cut -d= -f2)"
[ "$fp" = "$CA_SHA256" ] || { echo "Fel fingeravtryck på ca.pem: $fp" >&2; exit 1; }
install -m 0644 -o root -g root "$dir/ca.pem" /etc/pki/rsyslog/ca.pem
restorecon /etc/pki/rsyslog/ca.pem
tls="$(openssl s_client -connect "$LOG:6514" -CAfile /etc/pki/rsyslog/ca.pem \
        -verify_hostname "$LOGNAMN" </dev/null 2>&1 || true)"
echo "$tls" | grep -E 'subject=|issuer=|Verify return code'
echo "$tls" | grep -q 'Verify return code: 0 (ok)' \
  || { echo "TLS-kontrollen mot $LOGNAMN misslyckades. Kör tcpdump och felsök flödet." >&2; exit 1; }

echo "== 5. rsyslog: vidarebefordran över TLS med diskkö"
if [ -f /etc/rsyslog.d/60-brandvagg.conf ]; then
  mv /etc/rsyslog.d/60-brandvagg.conf "/root/60-brandvagg.conf.v4-$(date +%Y%m%d%H%M)"
  echo "   60-brandvagg.conf (klartext tcp/514) flyttad till /root"
fi
install -m 0644 -o root -g root "$dir/90-logg.conf" /etc/rsyslog.d/90-logg.conf
restorecon /etc/rsyslog.d/90-logg.conf
rsyslogd -N1
systemctl restart rsyslog

echo "== 6. auditd: root-kommandon och syslog-pluginet"
sed -i 's/^active *= *no/active = yes/' /etc/audit/plugins.d/syslog.conf
grep -E '^(active|args)' /etc/audit/plugins.d/syslog.conf
install -m 0640 -o root -g root "$dir/50-root-cmd.rules" /etc/audit/rules.d/50-root-cmd.rules
augenrules --load
service auditd restart   # inte systemctl, se studieguiden
auditctl -l | grep root-cmd

echo "== 7. Testhändelse"
id="sparbarhet-$(hostname -s)-$(date -u +%Y%m%dT%H%M%SZ)"
logger -p user.notice -t sparbarhet "$id"
sleep 3
journalctl -u rsyslog -n 5 --no-pager
echo
echo "== Klart på $(hostname -s). Kontrollera centralt på jump:  loggsök $id"
echo "   Raden ska ha kanalen TLS, värdnamnet $(hostname -s) och en tid som stämmer med mottagningstiden."
echo "   Fyll i raden i docs/vecka_05/verifiering.md. CTF: kontrollera U5.1 (eget id), U5.2, U5.3."
