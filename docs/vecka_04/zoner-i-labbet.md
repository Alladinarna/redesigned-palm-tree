# Zoner i labbet (vecka 4)

Flödestabellen ([flodestabell.md](../vecka_03/flodestabell.md)) beskriver alla zoner hos uppdragsgivaren. I labbet låter vi teamets fyra servrar representera några av zonerna. Resten finns bara på papper. Adresserna kommer från adressplanen ([adressplan.md](../vecka_02/adressplan.md)).

## Fördelning

| Server | Representerar zon | Adress i teamnätet (eth2) | Rader i flödestabellen som kan testas |
|---|---|---|---|
| elev-46 | DMZ (publik webb) | 10.40.1.146 | F4, F5, F9 (ut), F11 |
| elev-24 | Serverzon (applikation) | 10.40.1.98 | F8 (in), F9 (in), F10 (ut), F12 |
| elev-38 | Databaszon | 10.40.1.162 | F10 (in), F13 |
| elev-09 | Klientzon | 10.40.1.2 | F6, F7, F8 (ut) |

"In" och "ut" anger i vilken kedja regeln ligger på den servern. Ett internt flöde blir alltid två regler, en på varje server.

## Zoner som motsvaras av kursens infrastruktur

- **Adminzon** motsvaras av kursens jump-server (172.20.1.2). F16 realiseras som D1.
- **Loggzon** motsvaras av kursens gemensamma loggserver (172.20.1.58). F11–F13 realiseras i vecka 4 som D5 (TCP 514), och från vecka 5 med TLS på TCP 6514.

## Zoner som bara finns på papper

- Gästzon
- Infrastruktur (routrar). I labbet routar Hetzners gateway 10.40.1.1 mellan subnäten.

## Krav som bara gäller labbet

- **Jump-servern (172.20.1.2)** måste nå alla servrar på TCP 22 (D1), annars kan vi inte logga in.
- **ctf-servern (172.20.1.10)** måste nå alla servrar på TCP 22 (D2), eftersom CTF-kontrollerna loggar in därifrån. Enskilda labbar kan kräva mer. U3.4 testade till exempel webbservern på TCP 80. Sådana öppningar läggs till för den labb som kräver dem, inte som en generell regel för ctf-servern.
- **UDP 901–904 från ctf-servern** syntes i trafikbaslinjen (vecka 1). Det är kursens labbtrafik, inte en del av uppdragsgivarens design, och den tillåts inte i regelverket om inte en labb kräver det.
- **Driftflödena D3–D7** (DNS, NTP, logg till log, DHCP-förnyelse och paketuppdateringar) behövs på varje server under default deny. De står i flödestabellen.