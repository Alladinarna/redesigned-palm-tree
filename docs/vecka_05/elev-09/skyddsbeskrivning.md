# Skyddsbeskrivning – loggkedjan elev-09 (vecka 5)

## 1. Vem kan ändra eller radera loggen lokalt
Lokalt kan bara root ändra eller radera loggen. Filerna i /var/log ägs av root och är -rw-------, så ingen annan kommer åt dem. Kontot student kan bli root via sudo (det ligger i gruppen wheel) och kan därför röra allt lokalt. Journalen ligger dessutom i /run (i minnet) och försvinner vid omstart.

**Belägg:** `ls -l /var/log/secure /var/log/messages /var/log/cron` visar att alla tre är `-rw-------` och ägda av root, och `groups student` ger `student : student wheel` – wheel är gruppen som får använda sudo i Rocky Linux.

## 2. Vem kan ändra eller radera loggen centralt
Centralt kan jag inte ändra eller radera mina loggar – jag har inget konto på loggservern. Jag kan bara läsa mina egna rader med loggsök på jump. Bara den som administrerar loggservern kan röra dem. Det är en del av skyddet: även om någon tar över min server kommer de inte åt den centrala kopian, för de har inget konto på loggservern.

**Belägg:** loggsök på jump ger bara läsning – t.ex. `loggsök sshd` visar min "Accepted publickey"-rad från loggservern, men jag kan inte logga in eller ändra något där.

## 3. Lagringstid och rotation
Lokalt roteras loggarna varje vecka och fyra gamla filer sparas (weekly + rotate 4), sen raderas de äldsta – ca fyra till fem veckor bakåt. Auditloggen roterar auditd själv vid 8 MB och sparar upp till fem filer. Journalen ligger i minnet och försvinner vid omstart. Centralt skickas loggen dit direkt när den händer (inte efter rotationen) och sparas längre än lokalt – exakt tid vet jag inte, jag har inget konto på loggservern.

**Belägg:** `grep` i /etc/logrotate.conf ger `weekly` och `rotate 4`; `grep` i /etc/audit/auditd.conf ger `max_log_file = 8` och `num_logs = 5`.

## 4. Vad händer när mottagaren är onåbar
När loggservern är onåbar lägger rsyslog händelserna i min diskstödda kö i stället för att tappa dem. Kön ligger på disk (queue.filename), så den överlever även en omstart, och resumeRetryCount=-1 gör att den aldrig ger upp. När servern kommer tillbaka levereras allt i efterhand med sin gamla tidsstämpel. En ren minneskö hade tappat allt vid omstarten. Om kön till slut blir full börjar nya händelser tappas, men den gränsen har jag inte nått.

**Belägg från U5.2:** köfilerna `fwd.00000001` och `fwd.qi` skrevs till /var/lib/rsyslog vid omstarten, och händelsen skapades 07:22:50 men togs emot centralt 07:25:28 – 158 sekunder senare, med sin ursprungliga tidsstämpel.

## Bevisförstöringsscenario
En angripare med root kan ju ändra regler, policy och script, och radera alla filer som elev-09 kommer åt. Men de når inte den centrala kopian, för de har inget konto på loggservern. Och allt som hände innan de hann kapa flödet är ju redan skickat dit – även deras egen inloggning och root-kommandon, där auid visar vem det var fast det kördes som root. Stänger de av vidarebefordran så tystnar servern, och en server som plötsligt slutar skicka märks ju också centralt.