# Adressplan – Boiler Room (team 1, Alladinarna)
 
## Förutsättningar och antaganden
 
- Teamets tilldelade nät är 10.40.1.0/24 (teamnummer 1). Blocket är privat enligt RFC 1918.
- Planen omfattar IPv4. IPv6 är avstängt på labbservrarna och ingår inte i planen.
- Dimensioneringen utgår från kursens exempel för uppdragsgivaren (ett mellanstort företag) och är anpassad till teamets tilldelade /24. Cirka 25 % tillväxt är inräknad.
- Zonerna skiljs åt i fjärde oktetten, och subnäten ligger i storleksordning.
- Gateway: i uppdragsgivarens miljö reserverar vi första användbara adressen (.1 i subnätet) för gateway i varje subnät, och enheter börjar på andra adressen. Användbara för enheter = 2^värdbitar − 2 − 1. I labbet (Hetzner) är 10.40.1.1 den enda faktiska gatewayen, gemensam för hela nätet. Övriga subnäts .1-adresser är reserverade enligt vår konvention, inte av plattformen.
- Länknät dimensioneras som /30 eftersom vi inte vet om uppdragsgivarens routrar stödjer RFC 3021 (/31). Länknäten undantas från gateway-regeln. I labbet dokumenteras de men skapas inte, eftersom Hetzners gateway routar mellan subnäten.
- Zonnamnen är desamma som i zonskissen.
## Dimensionering
 
| Grupp | Idag | Med 25 % tillväxt |
|---|---|---|
| Klientzon | 44 | 55 |
| Gästzon | 20 | 25 |
| Serverzon (applikation) | 14 | 18 |
| Adminzon (drift och administration) | 6 | 8 |
| DMZ | 4 | 5 |
| Loggzon (logg och övervakning) | 3 | 4 |
| Databaszon | 4 | 5 |
| Infrastruktur (länknät mellan routrar) | 3 st à 2 adresser | |
 
## Adressplan
 
| Prefix | Syfte | Uträkning | Adressintervall för enheter (första–sista) | Ansvarig tjänst | Reserverat utrymme | Kommentar |
|---|---|---|---|---|---|---|
| 10.40.1.0/26 | Klientzon | 55 → 2⁶ − 2 − 1 = 61 → /26 | 10.40.1.2 – 10.40.1.62 | Arbetsplatser (DHCP) | Se nästa tabell | Gateway .1 (även Hetzners gateway för hela nätet), broadcast 10.40.1.63 |
| 10.40.1.64/27 | Gästzon | 25 → 2⁵ − 2 − 1 = 29 → /27 | 10.40.1.66 – 10.40.1.94 | Gästnät (DHCP) | Se nästa tabell | Gateway .65, broadcast 10.40.1.95 |
| 10.40.1.96/27 | Serverzon (applikation) | 18 → 2⁵ − 2 − 1 = 29 → /27 | 10.40.1.98 – 10.40.1.126 | Applikationsserver | Se nästa tabell | Gateway .97, broadcast 10.40.1.127 |
| 10.40.1.128/28 | Adminzon (drift och administration) | 8 → 2⁴ − 2 − 1 = 13 → /28 | 10.40.1.130 – 10.40.1.142 | jump (SSH 22) | Se nästa tabell | Gateway .129, broadcast 10.40.1.143 |
| 10.40.1.144/29 | DMZ | 5 → 2³ − 2 − 1 = 5 → /29 | 10.40.1.146 – 10.40.1.150 | Publik webb (HTTP 80, HTTPS 443) | Se nästa tabell | Gateway .145, broadcast 10.40.1.151. Fullt efter tillväxt – växer via reserven |
| 10.40.1.152/29 | Loggzon (logg och övervakning) | 4 → 2³ − 2 − 1 = 5 → /29 | 10.40.1.154 – 10.40.1.158 | log (syslog TCP 6514 med TLS) | Se nästa tabell | Gateway .153, broadcast 10.40.1.159. I vecka 4 tar log emot på TCP 514 i klartext, TLS från vecka 5 |
| 10.40.1.160/29 | Databaszon | 5 → 2³ − 2 − 1 = 5 → /29 | 10.40.1.162 – 10.40.1.166 | Databastjänst | Se nästa tabell | Gateway .161, broadcast 10.40.1.167. Fullt efter tillväxt – växer via reserven |
| 10.40.1.240/30 | Infrastruktur – länknät 1 | 2 → 2² − 2 = 2 → /30 | 10.40.1.241 – 10.40.1.242 | Routing (intern gateway) | – | Broadcast 10.40.1.243. Skapas inte i Hetzner |
| 10.40.1.244/30 | Infrastruktur – länknät 2 | 2 → 2² − 2 = 2 → /30 | 10.40.1.245 – 10.40.1.246 | Routing | – | Broadcast 10.40.1.247. Skapas inte i Hetzner |
| 10.40.1.248/30 | Infrastruktur – länknät 3 | 2 → 2² − 2 = 2 → /30 | 10.40.1.249 – 10.40.1.250 | Routing | – | Broadcast 10.40.1.251. Skapas inte i Hetzner |
 
## Reserverat utrymme mellan grupperna
 
| Intervall | Prefix | Status |
|---|---|---|
| 10.40.1.168 – 10.40.1.175 | /29 | Reserverat (tillväxt DMZ, Loggzon, Databaszon) |
| 10.40.1.176 – 10.40.1.191 | /28 | Reserverat (tillväxt Serverzon, Adminzon) |
| 10.40.1.192 – 10.40.1.223 | /27 | Reserverat (tillväxt Klientzon, Gästzon) |
| 10.40.1.224 – 10.40.1.239 | /28 | Reserverat för framtida zoner |
| 10.40.1.252 – 10.40.1.255 | /30 | Reserverat för infrastruktur (fjärde länknät) |
 
Zonerna ligger tätt, så ett subnät kan inte växa på plats. Tillväxt sker genom att ett nytt subnät tas ur reserven.
 
Reserverat utrymme får inte tas i bruk utan att planen uppdateras.
 
## Realisering i labbet (Hetzner)
 
Teamnätet 10.40.1.0/24 skapas med `moln nät skapa 10.40.1.0/24` av en person i teamet: Gabriel (elev-09). Varje medlem kopplar sin egen server med `moln koppla ADRESS`. Servern får då ett nytt nätkort, eth2.
 
| Zon | Labbtillgång | Adress | Skapas som subnät i Hetzner | Kommentar |
|---|---|---|---|---|
| DMZ | elev-46 | 10.40.1.146 (eth2) | Ja, 10.40.1.144/29 | |
| Serverzon (applikation) | elev-24 | 10.40.1.98 (eth2) | Ja, 10.40.1.96/27 | |
| Databaszon | elev-38 | 10.40.1.162 (eth2) | Ja, 10.40.1.160/29 | |
| Klientzon | elev-09 | 10.40.1.2 (eth2) | Ja, 10.40.1.0/26 | |
| Adminzon | jump | 172.20.1.2 (labbnätet) | Ja, 10.40.1.128/28 (ingen server kopplas) | jump ligger i labbnätet 172.20.1.0/24, utanför teamnätet |
| Loggzon | log | 172.20.1.58 (labbnätet) | Ja, 10.40.1.152/29 (ingen server kopplas) | log ligger i labbnätet 172.20.1.0/24, utanför teamnätet |
| Gästzon | – | – | Ja, 10.40.1.64/27 (ingen server kopplas) | Ingen motsvarighet i labbet |
| Infrastruktur | Hetzners gateway | 10.40.1.1 | Nej | Ersätter uppdragsgivarens routrar och länknät |
 
Alla sju zonsubnät skapas i Hetzner, så att adressplanen med subnät per zon är realiserad i sin helhet (kursmål 7). Länknäten skapas inte.
 
Flödestabellen och regelverket använder jumps och logs verkliga adresser (172.20.1.2 och 172.20.1.58), inte adresser i Adminzonen eller Loggzonen.
 
Trafik i teamnätet (eth2) och labbnätet (eth1) passerar inte molnbrandväggen och filtreras därför med nftables på varje server.
 
Nätet och alla sju zonsubnät skapades 26/10 och är kontrollerade med `moln status`, som visar gateway 10.40.1.1 för samtliga subnät. Alla fyra servrar är kopplade och svarar på ping. Hetzner tillåter subnät ned till /30, så alla zonsubnät i planen går att skapa.
 
## Vilka zoner ska nå varandra
 
Enligt zonskissen. Default deny gäller både mellan och inom zoner, in- och utgående. Exakta portar, riktningar och lager står i flödestabellen ([flodestabell.md](../vecka_03/flodestabell.md)). Radnumren nedan hänvisar dit.
 
Tillåtna flöden:
 
- Internet → DMZ (TCP 80/443) – F4, F5
- Gästzon → internet (webb och DNS) – F1–F3
- Klientzon → internet (webb och DNS) – F6, F7
- Klientzon → Serverzon (TCP 443) – F8
- DMZ → Serverzon (app-port TCP 8080) – F9
- Serverzon → Databaszon (TCP 5432) – F10
- DMZ, Serverzon, Databaszon, Adminzon och Infrastruktur → Loggzon (TCP 6514 med TLS, envägs; i vecka 4 TCP 514 i klartext, D5) – F11–F14, F21
- Behörig administratör (extern) → Adminzon/jump (SSH 22 + MFA) – F15
- Adminzon/jump → Gästzon, Klientzon, DMZ, Serverzon, Databaszon och Infrastruktur (SSH 22). Jump når inte Loggzonen med vanliga administratörskonton – F16
- Adminzon/jump → Loggzon (SSH 22) endast med separat loggadmin-konto – F17
- Adminzon/jump → samma zoner som F16 (ICMP echo, felsökning). Loggzonen ingår inte – F22
- Adminzon/jump → Loggzon (ICMP echo) endast från loggadmin-kontot – F24
- Serverzonerna → Hetzners DNS-resolvrar 185.12.64.1 och 185.12.64.2 (UDP/TCP 53) – F18
- Serverzonerna, Klientzon och Infrastruktur → Hetzners NTP-servrar 213.239.239.164–.166 (UDP 123, tidssynk) – F19
- Serverzonerna → internet (TCP 443, paketuppdateringar) – F20
- Serverzonerna → DHCP-servern (UDP 68 → 67, förnyelse av adresser) – F23
Inte tillåtet:
 
- DMZ → Databaszon direkt, all åtkomst till data går via Serverzonen
- Gästzon → interna zoner
- Loggzon → andra zoner
- Servrar → Adminzon
Se zonskissen i [reviderad-zonskiss2.0.png](../vecka_03/reviderad-zonskiss2.0.png).
 
## Metod
 
Uträkningarna är gjorda för hand och kontrolleras av gruppen och säkerställs med AI. AI (Claude) har använts som stöd vid sammanställningen.
