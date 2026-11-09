# Skyddsbeskrivning – loggkedjan på elev-38

Kedjan: händelse på servern → lokal logg → rsyslog → TLS på port 6514 → loggservern (172.20.1.58). Tre källor skickas med egen kö: kärnloggen (brandväggen), systemloggen och autentiseringsloggen. Auditposterna (audisp-syslog) följer med systemloggen.

## 1. Vem kan ändra eller radera loggen lokalt?

Alla loggfiler ägs av root och kan bara läsas och skrivas av root. Mitt konto student är med i gruppen wheel och får köra allt som root med sudo. Den som tar över student-kontot kan alltså ändra eller radera alla lokala loggar och stoppa rsyslog och auditd.

Belägg:
- `-rw------- 1 root root ... /var/log/secure`, `/var/log/messages` och `/var/log/audit/audit.log`
- `groups=1000(student),10(wheel)` och `(ALL) ALL` från `sudo -l`
- Journalen ligger i minnet (`/run/log/journal`) och försvinner vid omstart.

## 2. Vem kan ändra eller radera loggen centralt?

Jag har inget konto på loggservern och kan inte ändra eller radera mina rader där. Loggservern sorterar raderna efter avsändarens adress, så jag kan inte heller skriva i någon annans logg. Men loggservern känner bara igen mig på adressen (RFC 5425 §5.3). Den som tar över elev-38 kan därför skicka falska rader som ser ut att komma från elev-38. TLS skyddar transporten, inte innehållet. Enligt vår flödestabell (F17) ska bara ett separat loggadmin-konto nå loggservern med SSH. Det kan jag inte verifiera, eftersom loggservern är kursens server och jag inte kan se vem som kan radera där.

Belägg:
- `Verify return code: 0 (ok)` från `openssl s_client`: min server kontrollerar loggservern, inte tvärtom.
- `loggsök` visar bara rader från min egen adress.

## 3. Lagringstid och rotation

| Logg | Lokalt |
|---|---|
| messages och secure | logrotate varje vecka, `rotate 4` – ungefär fyra veckors historik |
| audit.log | `max_log_file = 8` (MB), `num_logs = 5`, `ROTATE` – högst fem filer à 8 MB, den äldsta skrivs över |
| journalen | ligger i minnet (`/run/log/journal`), 11,5 MB just nu, borta vid omstart |

Centralt: hur länge loggservern sparar mina rader har jag inte kunnat se och inte verifierat.

Belägg: `weekly` och `rotate 4` i `/etc/logrotate.conf` samt `/var/log/messages` och `/var/log/secure` i `/etc/logrotate.d/rsyslog`, `max_log_file` och `num_logs` i `/etc/audit/auditd.conf`, samt `ls -ld /run/log/journal` och `journalctl --disk-usage`.

## 4. Vad händer när mottagaren är onåbar?

Varje källa har en egen kö på disk: `queue.type="LinkedList"` med `queue.filename` (`fwd_kern`, `fwd_system` och `fwd_auth`), `queue.saveOnShutdown="on"` och `action.resumeRetryCount="-1"` (försöker för alltid). I U5.2 blockerade jag flödet till port 6514, startade om rsyslog två gånger och skickade en händelse kl. 20:43:11 UTC. Den togs emot 20:44:56, 105 sekunder senare, med sin ursprungliga tidsstämpel. Köfilerna skrevs vid omstarten (`fwd_system.00000001`, cirka 160 KB). Med en ren minneskö hade händelsen försvunnit vid omstarten.

Begränsning: jag har inte satt någon storleksgräns på kön och har inte testat vad som händer när en gräns nås.

## Scenario: en angripare med root på min server

Angriparen kan:
- radera `/var/log/secure` och `/var/log/messages`
- stoppa rsyslog och ta bort köfilerna i `/var/lib/rsyslog`
- blockera port 6514 så att nya rader inte lämnar servern
- stänga av auditd, eftersom reglerna inte är låsta (status `enabled 1`)

Det kedjan ändå fångar:
- Allt som redan har skickats finns kvar på loggservern, dit angriparen inte når.
- Auditposten för varje kommando skickas inom ungefär en sekund (U5.3: kommandot kördes 17:46:37 och togs emot 17:46:38), med `auid` som visar vem som ursprungligen loggade in. Kommandot som stoppar rsyslog hinner därför troligen skickas, men det har jag inte testat.
- En server som blir tyst syns centralt, som servern bad i U5.4 som slutade skicka loggar 10:05.

Det som ändå kan gå förlorat:
- Rader som ligger i kön och inte hunnit skickas.
- Rader som angriparen skickar i mitt namn, eftersom loggservern bara kontrollerar adressen.
- Ingen tittar automatiskt efter tystnaden än. Det kommer med detektionen i vecka 6.
