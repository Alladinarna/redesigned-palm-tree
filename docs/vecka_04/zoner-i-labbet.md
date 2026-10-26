# Zoner i labbet (vecka 4)

Flödestabellen i vecka 3 beskriver alla zoner hos uppdragsgivaren. I labbet låter vi teamets fyra servrar representera några av zonerna. Resten finns bara på papper.

## Fördelning

| Server | Representerar zon | Flöden i flödestabellen som kan testas |
|---|---|---|
| elev-46 | DMZ (publik webb) | Rad 4–5, 9, 11 |
| elev-24 | Serverzon (applikation) | Rad 9, 10, 12 |
| elev-38 | Databaszon | Rad 10, 13 |
| elev-09 | Klientzon | Rad 6–8 |

## Zoner som motsvaras av kursens infrastruktur

- **Adminzon** motsvaras av kursens jump-server (172.20.1.2).
- **Loggzon** motsvaras av kursens gemensamma loggserver (172.20.1.58).

## Zoner som bara finns på papper

- Gästzon
- Infrastruktur (routrar)

## Krav som bara gäller labbet

- **ctf-servern (172.20.1.10)** måste kunna nå våra servrar för att ctf-kontrollen ska fungera, till exempel i U3.4 där den testar webbservern på tcp/80. Det är ingen del av uppdragsgivarens design, men nekanderegeln får inte stoppa det.
- **Jump-servern** måste kunna nå alla servrar på SSH 22, annars kan vi inte logga in.
