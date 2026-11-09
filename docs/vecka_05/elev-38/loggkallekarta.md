# Loggkällekarta – elev-38 (Databaszon)

Servertiden är UTC. Exempelraderna är kopierade från elev-38.

| Källa | Var / hur den läses | Exempelrad (klistrad) | Vilken fråga den besvarar | Rotation | Hur långt bakåt | Tidsformat |
|---|---|---|---|---|---|---|
| Systemlogg (messages) | `/var/log/messages`, skrivs av rsyslog | `Nov  8 00:00:03 elev-38 systemd[1]: Reloaded The Apache HTTP Server.` | Vilka tjänster startades eller laddades om, och när? | logrotate varje vecka, `rotate 4` | Aktiv fil börjar 8 nov 00:00, äldre i roterade filer (ca fyra veckor) | `Nov  8 00:00:03`: månad, dag, tid, utan år och tidszon |
| Autentiseringslogg (secure) | `/var/log/secure` (authpriv) | `Nov  8 17:43:52 elev-38 sshd-session[10147]: Accepted password for student from 172.20.1.2 port 47632 ssh2` | Vem loggade in, när och från vilken adress? | logrotate varje vecka, `rotate 4` | Aktiv fil börjar 8 nov 17:43 | som messages |
| Auditlogg | `/var/log/audit/audit.log` (auditd), skickas via audisp-syslog | `type=USER_END msg=audit(1787664263.930:1864): pid=23967 uid=0 auid=0 ses=1 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023` | Vem körde vilket kommando som root (auid)? | `max_log_file = 8` MB, `num_logs = 5`, `ROTATE` | Aktiv fil börjar 25 aug 2026 (epoch 1787664263) | epoch-sekunder med millisekunder och serienummer: `msg=audit(TID:SERIENUMMER)` |
| Brandväggslogg (kärnan, nftables) | kärnmeddelanden med prefixen ZON-IN-DROP och ZON-UT-DROP, `journalctl -k -g ZON-` | `Nov 05 07:32:34 elev-38 kernel: ZON-UT-DROP IN= OUT=eth0 SRC=91.107.220.202 DST=104.20.23.154 LEN=60 PROTO=TCP SPT=57416 DPT=80 SYN` | Vilken trafik nekades, från vem till vem och på vilken port? | journalen ligger i minnet, ingen tidsrotation | sedan serverstart 2 nov (`/run/log/journal` skapades 07:54) | `Nov 05 07:32:34` (UTC) |
| Cron | `/var/log/cron` | `Nov  8 00:01:01 elev-38 CROND[9800]: (root) CMD (run-parts /etc/cron.hourly)` | Vilka schemalagda jobb körde som root, och när? | logrotate varje vecka, `rotate 4` | Aktiv fil börjar 8 nov 00:01 | som messages |
| Paketlogg (dnf) | `/var/log/dnf.log` | `2026-10-04T16:07:53+0000 INFO --- logging initialized ---` | Vilka paket installerades eller uppdaterades, och när? | inte kontrollerad | sedan 4 okt 2026 | ISO 8601 med `+0000` |
| Journal | systemd-journald i minnet (`/run/log/journal`), läses med `journalctl` | `Nov 09 06:02:48 elev-38 audisp-syslog[22683]: type=CRED_DISP msg=audit(1794204168.912:1715): pid=23550 uid=1000 auid=1000 ses=31` | Allt som loggats sedan start, samlat på ett ställe. Källa åt rsyslog. | ingen tidsrotation, 11,5 MB i minnet, borta vid omstart | sedan serverstart 2 nov | `Nov 09 06:02:48` (UTC) |

# Fem frågor och urval

| Fråga (tidsspann, subjekt, vad som ska fastställas) | Källor som krävs | Går att besvara idag? |
|---|---|---|
| Vem loggade in via SSH på elev-38 mellan 02.00 och 04.00 natten till söndag, med vilket konto och från vilken adress? | Autentiseringslogg | Ja. Skickas över TLS, verifierat 9 nov med `loggsök Accepted`. |
| Vilka kommandon kördes som root på elev-38 under en given timme, och vilket konto loggade ursprungligen in (auid)? | Auditlogg (EXECVE och SYSCALL) | Ja. U5.3, centralt med auid=1000. |
| Vilken utgående trafik från elev-38 nekades den senaste veckan, och till vilka mål och portar? | Brandväggslogg | Ja, över TLS sedan 5 nov. Före dess gick den i klartext på 514. |
| Slutade elev-38 skicka loggar under ett visst dygn, och när började tystnaden? | Systemlogg som regelbunden signal, och mottagningstiden centralt | Delvis. Luckan syns i mottagningstiden, men inget larm slår på tystnad. |
| Vilka schemalagda jobb körde som root natten till en viss dag? | Cron | Nej, bara lokalt. `cron.none` i `61-system.conf` håller den utanför. |

Hur länge loggservern sparar raderna centralt är inte verifierat.

# Strukna källor och skäl

| Struken källa | Varför ingen fråga behöver den |
|---|---|
| Journal | Samma händelser finns redan i secure, audit och kärnloggen. Den ligger dessutom bara i minnet. |
| Paketlogg (dnf) | Ingen av de fem frågorna handlar om paketens historik. |
| Webbserverlogg (httpd access_log) | Webbservern får inga förfrågningar på elev-38 och filen är tom. |
