# Skyddsbeskrivning av loggkedjan – vecka 5

Workshop 2, del 2. Varje svar ska ha belägg i form av ett kommando, en konfigurationsrad eller en rättighetsutskrift.

> **Utkast** (2/11). Beläggen kommer från elev-24, insamlade som `student` utan sudo. Rader märkta ⚠ fylls i när konfigurationen är på plats (workshop 2). Övriga servrar lägger till avvikelser från elev-24.

Loggkedjan: journald / auditd → rsyslog (diskkö) → TLS tcp/6514 → log 172.20.1.58 → `/var/log/remote/elev-NN/` (från vecka 6 även Wazuh).

## 1. Vem kan ändra eller radera loggen lokalt?

- Loggfilerna ägs av root och är bara läsbara och skrivbara för root:
  ```
  -rw-------. 1 root root  1546 Nov  2 07:48 secure
  -rw-------. 1 root root 17778 Nov  2 07:48 messages
  drwx------. 2 root root  4096 Aug 25 13:22 audit
  ```
  (`ls -l /var/log` på elev-24, 2/11)
- Journalen ligger i `/run/log/journal` (`drwxr-sr-x+ root systemd-journal`). Den kan läsas av gruppen `systemd-journal` och av dem som fått rätt genom ACL:en (studentkontot kan läsa sshd- och kernel-rader med `journalctl`). Bara root kan radera den (`journalctl --rotate --vacuum-time=1s`).
- Den som har root kan alltså ändra och radera allt lokalt, också kön i `/var/lib/rsyslog`. Det inkluderar varje konto med sudo. ⚠ Lägg in `sudo -l -U student` och `getent group wheel` som belägg.

## 2. Vem kan ändra eller radera loggen centralt?

- Ingen i teamet har något konto på loggservern. Vi kan bara söka i våra egna rader med `loggsök` på jump (studieguiden, avsnittet om loggkedjan).
- Loggservern sorterar raderna efter **avsändaradress**, inte efter värdnamnet i meddelandet. Root på elev-24 kan alltså inte skriva i någon annans loggar, men kan skicka falska rader *som elev-24* (RFC 5425 §5.3 och §6.1: mottagaren autentiserar inte avsändaren).
- Bara kursens administratörer kan ändra eller radera centralt. I uppdragsgivarens design motsvarar det F17 (separat loggadmin-konto från Adminzonen).

## 3. Lagringstid och rotation

| Var | Lagringstid | Belägg |
|---|---|---|
| Lokalt: `/var/log/secure`, `messages`, `cron` | Veckorotation, fyra gamla filer sparas, alltså 4–5 veckor | `/etc/logrotate.conf`: `weekly`, `rotate 4`, `dateext`. Äldsta filerna är `secure-20261011` och `messages-20261011` |
| Lokalt: journalen | Bara sedan senaste start. Försvinner vid omstart | `#Storage=auto` i `/etc/systemd/journald.conf` och `/var/log/journal` saknas, så journalen ligger bara i minnet |
| Lokalt: auditd | ⚠ `max_log_file`, `num_logs`, `max_log_file_action` | ⚠ `sudo grep -E '^(max_log_file\|num_logs\|max_log_file_action)' /etc/audit/auditd.conf` |
| Lokalt: kön | Tills den har levererats, högst 256 MB | `queue.maxDiskSpace="256m"` i [90-logg.conf](logginsamling/90-logg.conf) |
| Centralt: log | ⚠ Okänd. Fråga utbildaren i Slack | – |

## 4. Vad händer när mottagaren inte går att nå?

- Vidarebefordran har en egen **diskstödd kö**: `queue.type="LinkedList"` med `queue.filename="fwd_logg"`. Kön ligger i minnet så länge det går och skrivs till disk (`/var/lib/rsyslog/fwd_logg.*`) när den växer eller när rsyslog stoppas (`queue.saveOnShutdown="on"`).
- `action.resumeRetryCount="-1"`: rsyslog försöker leverera i all oändlighet och tappar inte rader bara för att log inte svarar.
- Kön tillhör bara den här åtgärden. De lokala filerna (`secure`, `messages`) skrivs som vanligt under avbrottet.
- **När gränsen nås** (256 MB på disk) tar kön inte emot fler rader. Nya rader till log kastas efter `queue.timeoutEnqueue` (standard 2 sekunder), medan de lokala filerna fortsätter. ⚠ Kontrollera beteendet mot rsyslog-dokumentationen för köparametrar.
- Belägg: U5.2 (blockera tcp/6514, starta om rsyslog två gånger, ta bort blockeringen och kontrollera att händelsen kommer fram i efterhand). ⚠ Lägg in `sudo ls -l /var/lib/rsyslog` efter den andra omstarten och `loggsök`-raden med mottagningstid och avsändartid.
- Med en ren minneskö (utan `queue.filename`) hade allt som låg i kön försvunnit vid omstarten.

## Scenario: angripare med root på elev-24

**Vad angriparen kan göra:**
- Radera eller ändra `/var/log/secure`, `messages` och `audit.log`.
- Tömma journalen eller starta om servern, så att journalen försvinner.
- Tömma kön i `/var/lib/rsyslog`.
- Stoppa rsyslog eller auditd.
- Ställa om klockan.
- Skicka falska rader som elev-24.

**Vad kedjan ändå fångar:**
- Inloggningen (sshd i authpriv) och `sudo`-kommandot skickas till log inom sekunder, innan angriparen hunnit radera något. Det som redan har levererats ligger utom räckhåll (avsnitt 2).
- auditd loggar EXECVE med **auid**, så root-kommandot kan knytas till det konto som loggade in, även efter `sudo -i` (U2).
- Att servern slutar skicka syns centralt som ett glapp i mottagningstiden (U4).
- En omställd klocka syns som skillnad mellan avsändartid och mottagningstid i `loggsök`.

**Det kedjan inte skyddar mot:**
- TLS skyddar bara transporten. Det som angriparen ändrar lokalt innan raden skickas, och falska rader som skickas efter intrånget, ser ut som äkta rader från elev-24.
- TLS ger inget kvitto på att en rad faktiskt sparades (RFC 5425 §6.3).
