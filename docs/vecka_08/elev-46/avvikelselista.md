# Avvikelselista – elev-46 (U8.1)

Tidsreferens: fångsten startar 2026-11-18 11:09 UTC
Tider nedan = sekunder från fångstens start.

| Tidpunkt | Flöde | Vad som avviker | Paketnummer | Säkerhet | Bedömning |
|---|---|---|---|---|---|
| 112-123 s | TCP SYN 172.20.1.110-> 172.20.1.146:många portar | sticker ut då det är 220 syn försök följt av rst från min server på olika portar på 11 sekunder | 91-536 | Hög | Angrepp, scanning, (T1046) |
| 128-135 s | 172.20.1.110-> 172.20.1.146: port 22 | 15 korta SSH sessioner mot samma adress och port | 539-690 | Hög | Angrepp, bruteforce, (T1110) |
| 135-152 s | 172.20.1.110-> 172.20.1.146: port 22 | En längre session  direkt efter dem 15 korta från samma källa. | 693-750 | Hög | Angrepp, lyckad inloggning, (T1078) |
| 140-141 s | 172.20.1.146-> 172.20.1.114: port 22 | Min server skickar SYN till en tredje värd på port 22. | 702-711 | Hög | Angrepp, lateral rörelse, (T1021) |
| 144-147 s | 172.20.1.146-> 185.12.64.1: port 53 | Domännamnet avviker trots att målet är den vanliga resolvern, långa base32 etiketter med sekvensnummer. | 716-738 | Hög | Angrepp, DNS tunnling, (T1048) |
| 0,3-175 s | 172.20.1.146-> 172.20.1.58: port 1514 | Min server skickar SYN paket var femte sekund till samma adress och port och får svar RST varje försök, pågår hela fångsten | 3-770 | Hög | Felkonfiguration, loggklient mot fel port (log tar bara emot på port 514/6514) |
