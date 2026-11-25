# Avvikelselista – elev-46 (U8.1)

Tidsreferens: fångsten startar 2026-11-18 12:09 UTC
Tider nedan = sekunder från fångstens start.

| Tidpunkt | Flöde | Vad som avviker | Paketnummer | Säkerhet | Bedömning |
|---|---|---|---|---|---|
| 112-123 s | TCP SYN 172.20.1.110-> 172.20.1.146:många portar | sticker ut då det är 220 syn försök följt av rst från min server på olika portar på 11 sekunder | 91-536 | Hög | Angrepp (T1046) |
| 128-135 s | 172.20.1.110-> 172.20.1.146: port 22 | 15 korta SSH sessioner mot samma adress och port | 539-750 |  |  |
| 135-152 s | 172.20.1.110-> 172.20.1.146: port 22 |  |  |  |  |
| 140-141 s | 172.20.1.146-> 172.20.1.114: port 22 |  |  |  |  |
| 144-147 s | 172.20.1.146-> 185.12.64.1: port 53 |  |  |  |  |
