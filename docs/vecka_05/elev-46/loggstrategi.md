# Loggstrategi – elev-46 (DMZ)

Loggkällekarta och urval från workshop 1, vecka 5. Alla exempelrader är kopierade från elev-46 den 4 november 2026.

## Loggkällekarta

| Källa | Var/hur den läses | Exempelrad | Vilken fråga den besvarar | Rotation | Hur långt bakåt | Tidsformat |
|---|---|---|---|---|---|---|
| Autentiseringslogg (sshd, sudo) | `/var/log/secure`, läses med sudo | `Nov  4 07:17:45 elev-46 sshd-session[7812]: pam_unix(sshd:session): session opened for user student(uid=1000) by student(uid=0)` | Vem loggade in med SSH på elev-46 den 4 november? | Varje vecka, 4 gamla filer sparas. Gamla filer får datum i namnet, t.ex. `secure-20261018` | Aktuell fil från 2 nov. Med roterade filer 4–5 veckor, äldsta är `secure-20261011` | RFC 3164: `Nov  4 07:17:45`. Saknar år, tidszon och millisekunder |
| Systemlogg (systemd, kernel m.fl.) | `/var/log/messages`, läses med sudo | `Nov  4 07:18:15 elev-46 systemd[1]: systemd-hostnamed.service: Deactivated successfully.` | Vilka tjänster stoppades på elev-46 den 4 november? | Varje vecka, 4 gamla filer sparas. Gamla filer får datum i namnet, t.ex. `messages-20261018` | Aktuell fil från 2 nov. Med roterade filer 4–5 veckor, äldsta är `messages-20261011` | RFC 3164: `Nov  4 07:18:15`. Saknar år, tidszon och millisekunder |
| Journalen (journald) | `/run/log/journal`, i RAM. Läses med `journalctl` | `Nov 04 07:53:27 elev-46 sudo[7874]: pam_unix(sudo:session): session opened for user root(uid=0) by student(uid=1000)` | Vad hände på elev-46 den 4 november, oavsett vilket program som loggade? | Efter storlek, inte tid. Högst 10 % av `/run` (`RuntimeMaxUse` standard). Använder nu 11,3 MB | Bara sedan senaste uppstart, 28 okt 10:15 UTC. Försvinner vid omstart | Lagras exakt med mikrosekunder i UTC. Visas som RFC 3164 som standard, eller ISO 8601 med `-o short-iso-precise` |
| Brandväggslogg (nftables, via kärnan) | Ingen egen fil. `journalctl -k \| grep ZON` eller `grep ZON /var/log/messages`. Skickas till loggservern via `60-brandvagg.conf`. Högst 10 rader/min loggas (`limit rate`) | `Nov 03 09:56:30 elev-46 kernel: ZON-UT-DROP IN= OUT=eth0 SRC=46.224.175.57 DST=71.6.155.70 ... PROTO=TCP SPT=80 DPT=58490 ... ACK PSH FIN` | Vilka adresser stoppades av brandväggen på elev-46, och mot vilka portar? | Veckovis i `messages`, storleksbaserad i journalen | Äldsta raden i journalen är från 28 okt 10:15. I `messages` 4–5 veckor | RFC 3164, samma som `messages` |
| Schemalagda jobb (crond) | `/var/log/cron`, läses med sudo | `Nov  4 08:01:01 elev-46 CROND[7893]: (root) CMDEND (run-parts /etc/cron.hourly)` | Vilka schemalagda jobb kördes på elev-46 den 4 november med root-kontot? | Varje vecka, 4 gamla filer sparas. Gamla filer får datum i namnet | Aktuell fil från 1 nov. Med roterade filer 4–5 veckor, äldsta är `cron-20261011` | RFC 3164 |
| Pakethantering (dnf) | `/var/log/dnf.rpm.log`, läsbar för alla | `2026-10-07T07:23:18+0000 SUBDEBUG Installed: zip-3.0-35.el9.x86_64` | Vilka paket installerades på elev-46 den 7 oktober? | Roteras av dnf själv vid 1 MB och sparar då upp till 4 gamla filer. Filen är 43 kB och har aldrig roterats | Sedan installationen 7 okt | ISO 8601 med år och tidszon (UTC), utan millisekunder. Egen fil, inte syslog |
| Granskningslogg (auditd) | `/var/log/audit/audit.log`, läses bara av root. Skrivs av auditd direkt, inte via journald eller rsyslog | `type=USER_START msg=audit(1793783487.774:1532): pid=7992 uid=1000 auid=1000 ses=37 ... acct="root" exe="/usr/bin/sudo" hostname=elev-46 ... res=success' UID="student" AUID="student"` | Vem körde kommandon som root på elev-46, och vem hade loggat in från början? | Roteras av auditd själv vid 8 MB (`max_log_file`). Sparar upp till 5 filer inklusive den aktuella (`num_logs`). Filen är 2,2 MB och har inte roterats | Äldsta raden är från 25 aug 2026, äldre än servern. Ärvd från avbilden servern klonades från | Sekunder sedan 1970 med millisekunder, plus serienummer: `msg=audit(1793783487.774:1532)`. UTC |
| Webbserverlogg (Apache httpd) | `/var/log/httpd/access_log` (besök) och `error_log` (fel). Mappen läses bara av root | `172.212.106.112 - - [04/Nov/2026:14:06:04 +0000] "GET /actuator/health HTTP/1.1" 404 196 "-" "Mozilla/5.0 zgrab/0.x"` | Vilka adresser besökte webbservern på elev-46, vilka sidor efterfrågades, och vilka fick fel? | Varje vecka, 4 gamla filer sparas, t.ex. `access_log-20261025` | Aktuell fil från 1 nov. Med roterade filer 4–5 veckor, äldsta är `access_log-20261011` | Apaches eget format: `[04/Nov/2026:14:06:04 +0000]`. År och tidszon (UTC), utan millisekunder. Egen fil, inte syslog |

## frågor och urval

| Fråga | Källor som krävs | Går att besvara idag? |
|---|---|---|
| 1. Vilka adresser stoppades av brandväggen på elev-46 mellan kl 21 och 23 den 6 november? | Brandväggslogg (kern, via journalen/messages) | Nej, tidpunkten har inte inträffat. Källan loggar redan och skickas centralt via `60-brandvagg.conf` |
| 2. Vilka adresser försökte ansluta via SSH till elev-46 den 5 november, och lyckades någon? | Autentiseringslogg (`secure`) | Nej, tidpunkten har inte inträffat. Källan finns lokalt men skickas inte centralt än |
| 3. Stoppades loggtjänsten (rsyslog) på elev-46 mellan 2 och 8 november, och vem gjorde det? | Systemlogg (att tjänsten stoppades) + autentiseringslogg eller granskningslogg (vem) | Delvis: 2–4 nov kan besvaras lokalt. Stoppas rsyslog slutar loggningen, och centralt syns bara den sista raden före stoppet |
| 4. Har något nytt schemalagt jobb börjat köras på elev-46 sedan 1 november, och som vilket konto? | Cron-logg | Ja, lokalt. `cron` finns sedan 1 nov, och roterade filer går längre bakåt |
| 5. Vem körde kommandon som root på elev-46 mellan kl 02 och 04 natten till 5 november, och vem hade loggat in från början? | Granskningslogg (auid) + autentiseringslogg (sudo) | Nej, tidpunkten har inte inträffat. Audit loggar lokalt men skickas inte centralt än |
| 6. Vilka adresser letade efter sidor som inte finns på webbservern på elev-46 den 4 november, och vilka sidor sökte de? | Webbserverlogg (`access_log`, svarskod 404) | Ja, lokalt. Skickas inte centralt än |

## Strukna källor och skäl

| Struken källa | Varför ingen fråga behöver den |
|---|---|
| Pakethantering (dnf) | Ingen av frågorna gäller paket. Installationer görs som root och syns därför i granskningsloggen |
| Journalen(journald) | Används som mellanled, rsyslog läser via imjournal och skickar vidare et som fårgorna behöver (systemlogg,autentiseringslogg,brandväggslogg). Att skicka den separat ger dubbletter. Den försvinner dessutom vi omstart. |
