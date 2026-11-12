# Skyddsbeskrivning av loggkedjan – elev-24 (vecka 5)

Varje svar har belägg i form av ett kommando, en konfigurationsrad eller en rättighetsutskrift.

Beläggen kommer från **elev-24**, insamlade 2026-11-02 mellan 07:50 och 08:14 UTC. Teamkamraternas skyddsbeskrivningar ligger i deras egna mappar. Det som inte har kunnat kontrolleras står under **Inte kontrollerat**.

Loggkedjan: journald / auditd (audisp-syslog) → rsyslog med diskkö → TLS tcp/6514 → log 172.20.1.58 (från vecka 6 även Wazuh).

## 1. Vem kan ändra eller radera loggen lokalt?

- Filerna i `/var/log` ägs av root och bara root kan läsa och skriva dem:
  ```
  -rw-------. 1 root root  1546 Nov  2 07:48 secure
  -rw-------. 1 root root 17778 Nov  2 07:48 messages
  -rw-------. 1 root root 2852079 Nov  2 08:13 audit.log      (i drwx------ /var/log/audit)
  drwx------. 2 root root  4096 Nov  1 00:00 /var/log/httpd
  ```
- Kön till log ligger i `/var/lib/rsyslog` och är bara åtkomlig för root:
  ```
  -rw-------. 1 root root 164326 Nov  2 08:11 fwd_logg.00000001
  -rw-------. 1 root root    560 Nov  2 08:11 fwd_logg.qi
  ```
- Journalen ligger i `/run/log/journal` och kan läsas av grupperna `adm` och `wheel` genom en ACL (`getfacl /run/log/journal`: `group:adm:r-x`, `group:wheel:r-x`).
- `student` är med i `wheel` (`id student`: `groups=1000(student),10(wheel),994(wireshark)`) och får köra allt som root (`sudo -l -U student`: `(ALL) ALL`).
- **Slutsats:** root kan ändra och radera all lokal logg och hela kön, och det kan därmed också `student` via sudo. Sudo kräver lösenord. Användningen loggas lokalt i `secure` och skickas till log, till exempel `sudo[22225] student : 1 incorrect password attempt ; ... COMMAND=/bin/systemctl restart rsyslog`, mottagen över TLS 08:09:45Z.

## 2. Vem kan ändra eller radera loggen centralt?

- Ingen i teamet har något konto på loggservern. Vi kan bara söka i våra egna rader med `loggsök` på jump (studieguiden vecka 5, avsnittet om loggkedjan).
- Loggservern sorterar raderna efter avsändaradress, inte efter värdnamnet i meddelandet (studieguiden). Varje rad i `loggsök` visar avsändaradressen, till exempel `172.20.1.124 elev-24`.
- Mottagaren autentiserar inte avsändaren med certifikat. Bara servern kontrollerar mottagarens certifikat (RFC 5425 §5.3 enligt studieguiden). rsyslog varnar `certificate file is not set` och `key file is not set` vid start.

## 3. Lagringstid och rotation

| Var | Lagringstid | Belägg |
|---|---|---|
| `/var/log/secure`, `messages`, `cron` | Veckorotation och fyra gamla filer sparas | `/etc/logrotate.conf`: `weekly`, `rotate 4`, `dateext`. Äldsta filerna är `secure-20261011` och `messages-20261011` |
| `/var/log/httpd/*log` | Som ovan, plus `notifempty` och `delaycompress` | `/etc/logrotate.d/httpd`. Äldsta är `access_log-20261011` |
| Journalen | Bara sedan senaste start, eftersom den ligger i minnet | `#Storage=auto` i `/etc/systemd/journald.conf`, `/var/log/journal` saknas, journalen ligger i `/run/log/journal` (8,0 MB) |
| auditd | Högst 5 filer à 8 MB | `/etc/audit/auditd.conf`: `max_log_file = 8`, `num_logs = 5`, `max_log_file_action = ROTATE`, `space_left_action = SYSLOG`, `disk_full_action = SUSPEND` |
| Kön till log | Tills den har levererats. Taket är 256 MB på disk | `queue.maxDiskSpace="256m"` i [90-logg.conf](90-logg.conf) |
| Centralt på log | **Inte kontrollerat** | Inget belägg. Frågan ställs till utbildaren |

## 4. Vad händer när mottagaren inte går att nå?

Kön är **diskstödd** (`queue.type="LinkedList"` och `queue.filename="fwd_logg"`), sparas vid avstängning (`queue.saveOnShutdown="on"`) och har obegränsat antal omförsök (`action.resumeRetryCount="-1"`).

**Test på elev-24 2026-11-02**, samma steg som i U5.2 men med ett eget id i stället för CTF-id:t:

| Tid (UTC) | Steg | Observation |
|---|---|---|
| 08:10:46 | Tillfällig regel `ip daddr 172.20.1.58 tcp dport 6514 counter drop` först i kedjan ut (inte i filen) | Regeln fick handle 26 |
| 08:10:46 | `systemctl restart rsyslog` | |
| 08:10:47 | `logger -t sparbarhet kotest-elev-24-20261102T081046Z` | |
| 08:11:58 | `systemctl restart rsyslog` igen, med blockeringen kvar | rsyslog: `action-1-builtin:omfwd queue[DA]: queue files exist on disk, re-starting with 88 messages` |
| 08:12:01 | Köfilerna före borttagningen | `fwd_logg.00000001` (164326 byte), `fwd_logg.qi` |
| 08:12:01 | Blockeringen borttagen | Räknaren stod på 67 paket och 250035 byte |
| 08:12:06 | Raden mottagen på log | `mottaget 2026-11-02T08:12:06.490Z TLS \| 2026-11-02T08:10:47.212852+00:00 172.20.1.124 elev-24 sparbarhet[22354] kotest-elev-24-20261102T081046Z` |

Händelsen skapades 08:10:47 och togs emot 08:12:06, efter två omstarter med mottagaren blockerad. **Kön höll.** Utan `queue.filename` hade kön bara funnits i minnet, och de 88 meddelandena hade inte funnits på disk vid omstarten.

Köfilerna låg kvar i `/var/lib/rsyslog` vid kontrollen 20 sekunder efter att blockeringen togs bort. Studieguiden säger att filerna kan ligga kvar tills rsyslog startas om nästa gång, och att leveransen ska kontrolleras centralt, inte på filerna.

**Observerat vid omstart (2/11):** rsyslog startade 08:28:09.38Z. dhclient började arbeta på eth1 08:28:09.33Z. Efter omstarten fastnade två anslutningar mot `172.20.1.58:6514` i `SYN-SENT` med den **publika** avsändaradressen 91.99.144.137 (eth0), medan kön växte till cirka 1,5 MB på disk. 08:30:21Z återupptogs leveransen via eth1 (`172.20.1.124 → 172.20.1.58:6514 ESTAB`), och raderna från perioden togs emot 08:30:22Z, till exempel `omstart-elev-24-20261102T082826Z` som skapades 08:28:26Z. Inga rader saknades vid kontrollen, men de kom fram cirka 2 minuter för sent.

**Varför eth0:** vid omstarten 08:38Z gick rsyslogs första SYN-paket ut på eth0 (`ZON-UT-DROP OUT=eth0 SRC=91.99.144.137`, 08:39:05.65Z), innan dhclient hade bundit eth1 (`bound to 172.20.1.124`, 08:39:07.50Z). När servern väl är uppe går 172.20.1.58 via eth1 (`ip route get 172.20.1.58`: `via 172.20.0.1 dev eth1 src 172.20.1.124`). Fördröjningen på cirka 128 s stämmer med `net.ipv4.tcp_syn_retries = 6` (1+2+4+8+16+32+64 = 127 s), som var inställt.

**Åtgärd 2/11 08:37Z:** D5 är låst till eth1 (`oifname "eth1"`). Den gör att paketen inte lämnar servern på eth0, men den kortar inte fördröjningen. Den uppmätta fördröjningen efter omstarten 08:38Z var cirka 128 s, och inga rader saknades ([Bevis](../../vecka_04/elev-24/Bevis/)). **Känd brist:** de första cirka 2 minuterna efter en omstart når loggarna loggservern först när kön skickas.

**Inte kontrollerat:** vad som händer när kön når taket på 256 MB.

## Scenario: angripare med root på elev-24

**Angriparen kan:**
- radera eller ändra `secure`, `messages`, `audit.log` och köfilerna (avsnitt 1)
- få journalen att försvinna genom en omstart (avsnitt 3)
- skicka egna rader som elev-24, eftersom mottagaren bara ser avsändaradressen (avsnitt 2)

**Kedjan fångar ändå:**
- **Inloggningen.** sshd-raden kom fram till log inom en halv sekund: skapad 08:12:32.389Z, mottagen 08:12:32.825Z (`Accepted publickey for student from 172.20.1.2 port 38950`).
- **Root-kommandon med vem som körde dem.** Auditposten kom fram med `auid=1000` (`AUID="student" UID="root"`, `key="root-cmd"`), mottagen 08:07:45Z.
- **Det som redan har levererats.** Det ligger på loggservern, där teamet inte har något konto.

TLS skyddar transporten. Det skyddar inte det som ändras i de lokala filerna innan en rad skickas, eller rader som angriparen själv skickar efter intrånget (studieguiden vecka 5, RFC 5425 §6).
