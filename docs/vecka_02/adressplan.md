# Adressplan – zonuppdraget

## Förutsättningar
- Uppdragsgivarens adressutrymme är 10.40.0.0/16 (privat enligt RFC 1918).
- Planen omfattar IPv4. IPv6 är avstängt på labbservrarna och ingår inte i planen.
- Antalet enheter per grupp bygger på antaganden om ett mellanstort företag, med 25 % tillväxt inräknad (dimensionering enligt kursens exempel).
- I varje subnät reserveras nätadressen, broadcastadressen och första användbara adressen (.1) för gateway. Adresser för enheter börjar därför på .2. Användbara för enheter = 2^värdbitar − 2 − 1.
- Länknäten undantas från gateway-regeln, eftersom de två adresserna där är routrarna själva.
- Varje grupp har ett eget värde i tredje oktetten. Det ger utrymme för tillväxt och förenklar summering per zon. Oanvänt utrymme är reserverat.
- Länknät dimensioneras som /30 eftersom vi inte vet om uppdragsgivarens routrar stödjer RFC 3021 (/31).
- Teamets labbtillgångar representerar grupperna så här: jump → Drift och administration, log → Logg och övervakning, elev-46/-24/-38/-09 → Servrar/DMZ, intern gateway → Länknät.

## Adressplan

| Prefix | Syfte | Uträkning | Adressintervall för enheter (första–sista) | Ansvarig tjänst | Reserverat utrymme | Kommentar |
|---|---|---|---|---|---|---|
| 10.40.0.0/24 | Klienter | 150 → 2⁸ − 2 − 1 = 253 → /24 | 10.40.0.2 – 10.40.0.254 | Arbetsplatser (DHCP) | 10.40.1.0 – 10.40.9.255(se nästa tabell) | Gateway .1, broadcast 10.40.0.255 |
| 10.40.10.0/26 | Gäst och besök | 50 → 2⁶ − 2 − 1 = 61 → /26 | 10.40.10.2 – 10.40.10.62 | Gästnät (DHCP) | 10.40.10.64 – 10.40.10.255 | Gateway .1, broadcast 10.40.10.63 |
| 10.40.20.0/27 | Servrar | 18 → 2⁵ − 2 − 1 = 29 → /27 | 10.40.20.2 – 10.40.20.30 | Webb och SSH (elevservrarna) | 10.40.20.32 – 10.40.20.255 | Gateway .1, broadcast 10.40.20.31 |
| 10.40.30.0/28 | Drift och administration | 8 → 2⁴ − 2 − 1 = 13 → /28 | 10.40.30.2 – 10.40.30.14 | jump (SSH 22) | 10.40.30.16 – 10.40.30.255 | Gateway .1, broadcast 10.40.30.15 |
| 10.40.40.0/29 | Databaser | 5 → 2³ − 2 − 1 = 5 → /29 | 10.40.40.2 – 10.40.40.6 | Databastjänst | 10.40.40.8 – 10.40.40.255 | Gateway .1, broadcast 10.40.40.7. |
| 10.40.50.0/29 | Logg och övervakning | 4 → 2³ − 2 − 1 = 5 → /29 | 10.40.50.2 – 10.40.50.6 | log (TCP 514, HTTP) | 10.40.50.8 – 10.40.50.255 | Gateway .1, broadcast 10.40.50.7 |
| 10.40.60.0/29 | DMZ | 5 → 2³ − 2 − 1 = 5 → /29 | 10.40.60.2 – 10.40.60.6 | Publik webb (HTTP 80,443) | 10.40.60.8 – 10.40.60.255 | Gateway .1, broadcast 10.40.60.7. |
| 10.40.250.0/30 | Länknät 1 | 2 → 2² − 2 = 2 → /30 | 10.40.250.1 – 10.40.250.2 | Routing (intern gateway) | – | Broadcast 10.40.250.3 |
| 10.40.250.4/30 | Länknät 2 | 2 → 2² − 2 = 2 → /30 | 10.40.250.5 – 10.40.250.6 | Routing | – | Broadcast 10.40.250.7 |
| 10.40.250.8/30 | Länknät 3 | 2 → 2² − 2 = 2 → /30 | 10.40.250.9 – 10.40.250.10 | Routing | 10.40.250.12 – 10.40.250.255 | Broadcast 10.40.250.11 |

## Reserverat utrymme mellan grupperna

| Intervall | Status |
|---|---|
| 10.40.1.0 – 10.40.9.255 | Reserverat (klienternas tillväxt) |
| 10.40.11.0 – 10.40.19.255 | Reserverat (gäst och besök tillväxt) |
| 10.40.21.0 – 10.40.29.255 | Reserverat (servrar tillväxt) |
| 10.40.31.0 – 10.40.39.255 | Reserverat (drift och admistration tillxäxt) |
| 10.40.41.0 – 10.40.49.255 | Reserverat (Databaser tillväxt)|
| 10.40.51.0 – 10.40.59.255 | Reserverat (logg och övervakning tillväxt) |
| 10.40.61.0 – 10.40.249.255 | Reserverat för framtida grupper |
| 10.40.251.0 – 10.40.255.255 | Reserverat för infrastruktur |

Reserverat utrymme får inte tas i bruk utan att planen uppdateras.

## Vilka subnät ska nå varandra

Tillåtna flöden (allt annat blockeras som standard):

- Gäst och besök → endast internet
- Internet → DMZ (webbservern) (TCP 80/443)
- Klienter → Servrar (nödvändiga tjänster) och internet
- DMZ(webbserver) → Servrar (endast app-port)
- Servrar → Databaser (endast Databas-port)
- Drift och administration (jump) → alla interna subnät (SSH 22)
- DMZ(webbserver), Servrar, Databaser och jump → Logg och övervakning (TCP 514, envägs)
- Behöriga administratörer(internet) → Drift och administration/jump(ssh 22)

Inte tillåtet:
- DMZ → Databaser direkt, all åtkomst till data går via Servrar
- Gäst och besök → interna subnät
- Logg och övervakning → andra subnät

Se zonskissen i [vecka_02](zonskiss.png).

## Metod
Uträkningarna är gjorda för hand och kontrollerade med ipcalc på elev-46, 2026-10-14T18:55:02Z. AI (Claude) har använts som stöd vid sammanställningen.
