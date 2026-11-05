# Skyddsbeskrivning – elev-46 (DMZ)

Skyddsbeskrivning av loggkedjan från elev-46 till loggservern log.sec.chas-lab.dev (172.20.1.58). Konfigurationen finns i [90-logg.conf](90-logg.conf).

## 1. Vem kan ändra eller radera loggen lokalt?

Loggfilerna ägs av root och kan bara läsas och skrivas av root. Kontot student kan bli root med sudo, och kan därför ändra eller radera allt lokalt.

Belägg:
```
$ ls -l /var/log/secure /var/log/messages /var/log/cron
-rw-------. 1 root root  38166 Nov  5 09:01 /var/log/cron
-rw-------. 1 root root 219491 Nov  5 09:16 /var/log/messages
-rw-------. 1 root root  34146 Nov  5 09:16 /var/log/secure

$ sudo ls -l /var/log/audit/audit.log
-rw-------. 1 root root 2476412 Nov  5 09:24 /var/log/audit/audit.log

$ groups student
student : student wheel
Wheel är gruppen som får använda sudo i rocky linux, därför kan student bli root.
```

Journalen ligger i RAM (`/run/log/journal`) och försvinner vid omstart. Alla med root kan därför radera den genom att starta om servern.

## 2. Vem kan ändra eller radera loggen centralt?

Jag har inget konto på loggservern. Jag kan bara läsa mina egna rader med `loggsök` på jump. Troligen kan bara kursens administratörer ändra eller radera loggar centralt. Den som tar sig in på elev-46 som root når alltså inte det som redan har skickats.

Belägg:
```
$ ssh 172.20.1.58          # från jump
elev-46@172.20.1.58: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).

$ loggsök spar92b56776     # läsrätt, inget mer
mottaget 2026-11-05T07:41:25.783Z TLS | 2026-11-05T07:41:25+00:00 172.20.1.146 elev-46 sparbarhet[3056]: U5.1 spar92b56776
```

## 3. Lagringstid och rotation

**Lokalt:**

| Källa | Rotation | Hur länge |
|---|---|---|
| secure, messages, cron | Veckovis, 4 gamla filer (`weekly`, `rotate 4`) | Ca 5 veckor |
| Journalen | Efter storlek, högst 10 % av `/run`, i RAM | Bara till nästa omstart |
| Granskningslogg (audit) | Vid 8 MB, upp till 5 filer (`max_log_file`, `num_logs`) | Beror på mängden händelser, inte tid |
| Webbserverlogg (httpd) | Veckovis, 4 gamla filer | Ca 5 veckor |

Belägg:
```
$ grep -E "^weekly|^rotate" /etc/logrotate.conf
weekly
rotate 4

$ sudo grep -E "^(max_log_file|num_logs|max_log_file_action)" /etc/audit/auditd.conf
max_log_file = 8
num_logs = 5
max_log_file_action = ROTATE
```

**Centralt:** okänt, styrs av kursens loggserver

## 4. Vad händer när mottagaren är onåbar?

rsyslog lägger händelserna i en kö i minnet (`queue.type="LinkedList"`). Med `queue.filename` går kön över till disk, och `queue.saveOnShutdown="on"` sparar den när rsyslog stängs. `action.resumeRetryCount="-1"` gör att rsyslog försöker skicka tills loggservern svarar.

Belägg från U5.2: flödet till 6514 blockerades och rsyslog startades om två gånger.
```
Före andra omstarten, kön i minnet:
-rw-------. 1 root root 123 Nov  5 08:36 imjournal.state

Efter andra omstarten, kön sparad på disk:
-rw-------. 1 root root 30720 Nov  5 08:39 fwd_tls.00000001
-rw-------. 1 root root   556 Nov  5 08:39 fwd_tls.qi

Centralt efter att blockeringen togs bort:
mottaget 2026-11-05T08:40:09.937Z TLS | 2026-11-05T08:36:51+00:00 172.20.1.146 elev-46 kotest[3193]: U5.2 spar84922b06
```
Händelsen skapades 08:36:51 och togs emot 08:40:09, 198 sekunder senare. Den behöll sin ursprungliga tidsstämpel.

**Gräns:** ingen `queue.maxDiskSpace` är satt, så kön har ingen övre gräns. Vid ett långt avbrott kan den fylla disken. Då kan rsyslog inte längre skriva, och nya händelser förloras. En rimlig förbättring är `queue.maxDiskSpace="100m"`.

## 5. Scenario: en angripare med root försöker förstöra bevis

En angripare har tagit sig in på elev-46 och fått root. För att dölja vad hen gör kan hen:
1. stoppa rsyslog (`systemctl stop rsyslog`), så att inget mer skickas,
2. blockera tcp 6514 i nftables, så att kön aldrig töms,
3. radera köfilerna i `/var/lib/rsyslog/`,
4. radera eller ändra de lokala loggarna och starta om servern, så att journalen försvinner.

**Vad kedjan ändå fångar:**
- **Allt som redan har skickats** ligger på loggservern, utom räckhåll för angriparen.
- **Själva stoppet loggas.** `sudo systemctl stop rsyslog` skrivs till secure och skickas innan rsyslog hinner stanna. Det sista loggservern får är alltså beviset på stoppet, med vilket konto som körde det.
- **Luckan syns.** När en server som brukar logga flera rader i minuten plötsligt tystnar, är tystnaden i sig en varningssignal. U5.4 visade samma mönster: arena tystnade direkt efter att kontot drift stoppade rsyslog.

**Vad kedjan inte fångar:** det angriparen gör **efter** stoppet. TLS skyddar loggarna på vägen, men inte mot en angripare som redan har root på avsändarservern.
