# Flödestabell vecka 4: driftflöden och rader per server

Driftflödena D1–D7 och de interna flödena mellan teamservrarna står nu i själva [flödestabellen](../../vecka_03/flodestabell.md), avsnittet *Realisering i labbet*. Den här filen sammanfattar bara vilka rader som hamnar på vilken server. Id:t (F1–F24, D1–D7) används som kommentar i nftables och som början på beskrivningen i molnbrandväggen.

## Zonernas adresser i labbet

Ur [adressplanen](../../vecka_02/adressplan.md) (teamnät 10.40.1.0/24) och [zoner-i-labbet](../zoner-i-labbet.md). Jump och loggservern ligger kvar i kursens labbnät, så reglerna använder deras verkliga adresser.

| Zon | Adress i reglerna | Labbserver |
|---|---|---|
| Klientzon | 10.40.1.0/26 | elev-09 (10.40.1.2) |
| Serverzon | 10.40.1.96/27 | elev-24 (10.40.1.98) |
| Databaszon | 10.40.1.160/29 | elev-38 (10.40.1.162) |
| DMZ | 10.40.1.144/29 | elev-46 (10.40.1.146) |
| Adminzon | 172.20.1.2 | jump |
| Loggzon | 172.20.1.58 | log |
| Kursens kontrolltjänst | 172.20.1.10 | ctf |

## Rader per server

Alla fyra har D1–D7 och F22 (ping från jump). NTP (D4/F19) är låst till ntp.hetzner.com (213.239.239.164–.166) på värden och i molnet. Utöver det:

| Server | Zon | In | Ut | Mapp |
|---|---|---|---|---|
| elev-09 | Klientzon | – | F6 (webb tcp/80, 443), F8 (→ Serverzon tcp/443) | [elev-09](elev-09/) |
| elev-24 | Serverzon | F8 (från Klientzon tcp/443), F9 (från DMZ tcp/8080) | F10 (→ Databaszon tcp/5432), F12 (→ log, som D5 i v4) | [elev-24](elev-24/) |
| elev-38 | Databaszon | F10 (från Serverzon tcp/5432) | F13 (→ log, som D5 i v4) | [elev-38](elev-38/) |
| elev-46 | DMZ | F4–F5 (från internet tcp/80, 443) | F9 (→ Serverzon tcp/8080), F11 (→ log, som D5 i v4) | [elev-46](elev-46/) |

F11–F13 realiseras i vecka 4 som D5 (TCP 514 i klartext). TCP 6514 med TLS läggs till i vecka 5, och fram till dess nekas den porten.

Ingen generell öppning för ctf → tcp/80. Den tidigare regeln L1 gällde U3.4, som är stängd. Öppningar för enskilda labbar läggs bara till när en labb kräver det ([zoner-i-labbet](../zoner-i-labbet.md)).

Varje mapp har regelverket (`<server>-zon.nft`), rsyslog-filen, molnbrandväggen, spårbarhetslistan, testfallen, testskriptet och testprotokollet.
