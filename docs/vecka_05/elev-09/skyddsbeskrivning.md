# Skyddsbeskrivning – loggkedjan elev-09 (vecka 5)

## 1. Vem kan ändra eller radera loggen lokalt
Lokalt kan bara root ändra eller radera loggen. Filerna i /var/log är ägda av root och -rw-------, så ingen annan kommer åt dem. En vanlig användare måste bli root (via sudo) för att röra dem.
Belägg: ls -l /var/log

## 2. Vem kan ändra eller radera loggen centralt
Centralt kan jag inte ändra eller radera mina loggar, då jag inte har något konto på loggservern. Bara root kan administrera och röra dem. Det är en del av skyddet: även om de tar över min server kommer de inte åt den centrala kopian, för de har inget konto på loggservern.
Belägg: inget konto på loggservern, loggsök är bara läsning.

## 3. Lagringstid och rotation
Lokalt roteras loggarna varje vecka och behålls i fyra veckor (logrotate: weekly + rotate 4), sen raderas de äldsta. Centralt skickas loggen dit direkt när den händer, inte efter rotationen, och sparas längre än fyra veckor – så även när den lokala filen är borta finns kopian kvar centralt.
Belägg: /etc/logrotate.conf (weekly, rotate 4), /etc/logrotate.d/rsyslog

## 4. Vad händer när mottagaren är onåbar
När loggservern är onåbar lägger rsyslog händelserna i min diskstödda kö i stället för att tappa dem. Kön ligger på disk (queue.filename), så den överlever även en omstart, och resumeRetryCount=-1 gör att den aldrig ger upp. När servern kommer tillbaka levereras allt i efterhand med sin gamla tidsstämpel. En ren minneskö hade tappat allt vid omstarten. Om kön till slut blir full börjar nya händelser tappas, men den gränsen har jag inte nått.
Belägg: U5.2, fwd-filerna i /var/lib/rsyslog, min 90-logg.conf

## Bevisförstöringsscenario
En angripare med root kan ju ändra regler, policy och script, och radera alla filer som elev-09 kommer åt. Men de når inte den centrala kopian, för de har inget konto på loggservern. Och allt som hände innan de hann kapa flödet är ju redan skickat dit – även deras egen inloggning och root-kommandon, där auid visar vem det var fast det kördes som root. Stänger de av vidarebefordran så tystnar servern, och en server som plötsligt slutar skicka märks ju också centralt.