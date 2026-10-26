# Zoner i labbet (vecka 4)

Flödestabellen i vecka 3 beskriver alla zoner hos uppdragsgivaren. I labbet låter vi teamets fyra servrar representera några av zonerna. Resten finns bara på papper.

## Fördelning

Adresserna i teamnätet 10.40.1.0/24 kommer från [adressplanen](../vecka_02/adressplan.md). Servern får adressen på eth2 när den kopplas med `moln koppla`.

| Server | Representerar zon | Subnät | Adress i teamnätet (eth2) | Adress i labbnätet (eth1) | Flöden i flödestabellen som kan testas |
|---|---|---|---|---|---|
| elev-46 | DMZ (publik webb) | 10.40.1.144/29 | 10.40.1.146 | 172.20.1.146 | Rad 4–5, 9, 11, 16, 22 |
| elev-24 | Serverzon (applikation) | 10.40.1.96/27 | 10.40.1.98 | 172.20.1.124 | Rad 8, 9, 10, 12, 16, 22 |
| elev-38 | Databaszon | 10.40.1.160/29 | 10.40.1.162 | 172.20.1.138 | Rad 10, 13, 16, 22 |
| elev-09 | Klientzon | 10.40.1.0/26 | 10.40.1.2 | 172.20.1.109 | Rad 6–8, 16, 22 |

Alla fyra har dessutom driftflödena D1–D7, se [flodestabell-driftfloden](zonuppdelning/flodestabell-driftfloden.md). Regelverk och tester per server finns i [zonuppdelning](zonuppdelning/).

## Zoner som motsvaras av kursens infrastruktur

- **Adminzon** motsvaras av kursens jump-server (172.20.1.2).
- **Loggzon** motsvaras av kursens gemensamma loggserver (172.20.1.58).
- **Jump och loggservern** ligger kvar på 172.20.1.0/24, så reglerna ska använda deras verkliga adresser och inte subnäten för Adminzonen (10.40.1.128/28) och Loggzonen (10.40.1.152/29) i adressplanen.

## Zoner som bara finns på papper

- Gästzon (10.40.1.64/27)
- Infrastruktur (routrar, länknät 10.40.1.240/30 ×3). I labbet ersätts de av Hetzners gateway 10.40.1.1.

## Krav som bara gäller labbet

- **ctf-servern (172.20.1.10)** måste kunna nå våra servrar för att ctf-kontrollen ska fungera: SSH på tcp/22 (D2) och webbservern på tcp/80 (L1). Det är ingen del av uppdragsgivarens design, men nekanderegeln får inte stoppa det.
- **Jump-servern** måste kunna nå alla servrar på SSH 22 (rad 16 / D1), annars kan vi inte logga in.
