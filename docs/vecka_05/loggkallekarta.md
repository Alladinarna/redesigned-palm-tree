# Loggkällekarta – vecka 5

Workshop 1, del 1. Varje medlem fyller i sin egen server. Varje rad ska ha en exempelrad klistrad från den egna servern, med serverns värdnamn.

Samma händelse kan synas på två ställen: sshd skriver till journalen, och rsyslog läser journalen (imjournal) och skriver samma rad till `/var/log/secure`. Det är **en** händelse i två lagringar, inte två händelser.

## elev-24 (Serverzon, Stef)

Insamlat 2026-11-02 mellan 07:50 och 08:14 UTC, först som `student` och sedan med sudo.

| Källa | Var / hur den läses | Exempelrad (klistrad) | Vilken fråga den besvarar | Rotation | Hur långt bakåt | Tidsformat |
|---|---|---|---|---|---|---|
| Journalen (journald) | `journalctl` (alla källor), `journalctl -o json` för alla fält | `2026-10-28T07:58:54+0000 elev-24 chronyd[656]: Selected source 213.239.239.165 (ntp.hetzner.com)` | Vad hände på servern sedan senaste start, och från vilken process/enhet? | `Storage=auto` och `/var/log/journal` saknas, så journalen ligger bara i minnet (`/run/log/journal`) | Sedan senaste start (28/10 07:58). 8,0 MB enligt `journalctl --disk-usage`. Försvinner vid omstart | Mikrosekunder sedan epoch (`__REALTIME_TIMESTAMP`), visas i serverns tidszon (UTC) |
| Autentisering, sshd (authpriv) | `sudo tail /var/log/secure`, `journalctl -u sshd` | `2026-11-02T07:48:26+0000 elev-24 sshd-session[9000]: Accepted publickey for student from 172.20.1.2 port 40444 ssh2: ED25519 SHA256:62gVAPYE2mhMSTdVqFMnTpItHPLDMrMHfS3gky8AqC0` | Vem loggade in, när, från vilken adress och med vilken nyckel? | logrotate: `weekly`, `rotate 4`, `dateext` (`/etc/logrotate.conf`, `/etc/logrotate.d/rsyslog`) | Fyra roterade filer plus den aktuella. Äldsta: `secure-20261011` | I filen: RFC 3164-format (`Nov  2 07:48:26`, utan år och tidszon). Raden ovan är journalens `short-iso` |
| sudo (authpriv) | `sudo grep sudo /var/log/secure`, `journalctl _COMM=sudo` | `2026-11-02T07:48:09+0000 elev-24 sudo[8996]:  student : a password is required ; PWD=/home/student ; USER=root ; COMMAND=/sbin/nft list chain inet zon ut` | Vem försökte bli root, när och med vilket kommando, och lyckades det? | Som `/var/log/secure` | Som `/var/log/secure` | Som `/var/log/secure` |
| Paketfiltret (kern, nftables) | `journalctl -k -g ZON-`, i filen `/var/log/messages` | `2026-11-02T07:28:50+0000 elev-24 kernel: ZON-UT-DROP IN= OUT=eth2 SRC=10.40.1.98 DST=10.40.1.146 LEN=60 TOS=0x00 PREC=0x00 TTL=64 ID=53482 DF PROTO=TCP SPT=35166 DPT=22 WINDOW=64860 RES=0x00 SYN URGP=0` | Vilken trafik stoppades av regelverket, mellan vilka zoner och på vilken port? | Som `/var/log/messages` (weekly, rotate 4). Begränsas av `limit rate 10/minute` i nft-regeln | Fyra veckor plus den aktuella. Äldsta: `messages-20261011` | Som `/var/log/messages` |
| Systemloggen (`/var/log/messages`) | `sudo tail /var/log/messages`, `journalctl` | `2026-11-01T00:00:03+0000 elev-24 rsyslogd[976]: [origin software="rsyslogd" swVersion="8.2510.0-2.el9_8.2" x-pid="976" x-info="https://www.rsyslog.com"] rsyslogd was HUPed` | Startades tjänster om, gick klockan rätt (chronyd), slutade rsyslog leverera? | weekly, rotate 4 | Äldsta: `messages-20261011` | RFC 3164 i filen |
| rsyslog själv | `journalctl -u rsyslog` | `2026-10-28T08:01:00+0000 elev-24 rsyslogd[976]: action 'action-1-builtin:omfwd' resumed (module 'builtin:omfwd') [v8.2510.0-2.el9_8.2 try https://www.rsyslog.com/e/2359 ]` | När tappade servern kontakten med loggservern, och när kom den tillbaka? | Journalen (bara i minnet) | Sedan senaste start | Som journalen |
| auditd | `sudo ausearch --input-logs -k root-cmd -i`, filen `/var/log/audit/audit.log` (`-rw------- root`, katalogen `drwx------ root`) | `type=EXECVE msg=audit(1793607209.973:1767): argc=4 a0="ausearch" a1="--input-logs" a2="-k" a3="root-cmd"` | Vilka kommandon kördes med root-behörighet, och av vilken inloggad person (auid)? | auditd roterar själv: `max_log_file = 8` (MB), `num_logs = 5`, `max_log_file_action = ROTATE` (`/etc/audit/auditd.conf`) | Högst 5 filer à 8 MB. Den aktuella filen var 2,8 MB 2/11 08:13 | `msg=audit(EPOCH.millisekunder:serienummer)` |
| cron | `sudo tail /var/log/cron`, `journalctl -t CROND` | `2026-11-02T07:01:01+0000 elev-24 CROND[8840]: (root) CMDEND (run-parts /etc/cron.hourly)` | Vilka schemalagda jobb kördes? | weekly, rotate 4 | Äldsta: `cron-20261011` | RFC 3164 i filen |
| Webbservern (httpd) | `sudo tail /var/log/httpd/error_log` och `access_log` (katalogen är `drwx------ root`). httpd är aktiv | `[Sun Nov 01 00:00:03.965526 2026] [core:notice] [pid 708:tid 708] AH00094: Command line: '/usr/sbin/httpd -D FOREGROUND'` (error_log). `access_log` är tom sedan rotationen 25/10 | Vilka anrop fick applikationen, från vilka adresser och med vilket svar? | `/etc/logrotate.d/httpd` (`notifempty`, `delaycompress`) med globala `weekly` och `rotate 4` | Äldsta: `access_log-20261011` och `error_log-20261011` | error_log: `[Sun Nov 01 00:00:03.965526 2026]` (lokal tid, utan tidszon) |
| dnf | `tail /var/log/dnf.rpm.log` (läsbar för alla) | `2026-11-02T07:16:29+0000 INFO --- logging initialized ---` | Vilka paket installerades eller uppdaterades, och när? | `/etc/logrotate.d/dnf` gäller bara `hawkey.log` (weekly, rotate 4). `dnf.log` och `dnf.rpm.log` har ingen egen regel i `/etc/logrotate.d/` | `dnf.log` var 776 kB 2/11 och har inga roterade filer i `/var/log` | ISO 8601 med tidszon |

Efter vecka 5-konfigurationen 2/11 08:07Z skickas sshd, sudo, paketfiltret, auditd och systemloggen från elev-24 till log över TLS, se [verifiering.md](verifiering.md).

Kommandon som användes: `ls -l /var/log`, `journalctl -u sshd -n 3 -o short-iso`, `journalctl -k -g ZON-`, `journalctl _COMM=sudo`, `journalctl -u rsyslog`, `journalctl -t CROND`, `journalctl --disk-usage`, `grep -i storage /etc/systemd/journald.conf`, `cat /etc/logrotate.conf /etc/logrotate.d/rsyslog /etc/logrotate.d/httpd /etc/logrotate.d/dnf`, och med sudo `grep ... /etc/audit/auditd.conf`, `ls -l /var/log/audit /var/log/httpd`, `tail -n 1 /var/log/httpd/error_log`, `ausearch --input-logs -k root-cmd`.

## elev-09 (Klientzon, Gabriel)

| Källa | Var / hur den läses | Exempelrad (klistrad) | Vilken fråga den besvarar | Rotation | Hur långt bakåt | Tidsformat |
|---|---|---|---|---|---|---|
| | | | | | | |

## elev-38 (Databaszon, Naima)

| Källa | Var / hur den läses | Exempelrad (klistrad) | Vilken fråga den besvarar | Rotation | Hur långt bakåt | Tidsformat |
|---|---|---|---|---|---|---|
| | | | | | | |

## elev-46 (DMZ, Hugo)

| Källa | Var / hur den läses | Exempelrad (klistrad) | Vilken fråga den besvarar | Rotation | Hur långt bakåt | Tidsformat |
|---|---|---|---|---|---|---|
| | | | | | | |
