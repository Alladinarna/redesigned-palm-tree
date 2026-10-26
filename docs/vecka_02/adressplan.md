# Adressplan – zonuppdraget

> **Revision vecka 4 (utkast, 2026-10-26):** Teamet Alladinarna har fått teamnummer **T = 1** och därmed det privata nätet **10.40.1.0/24** i Hetzner. Planen är omräknad så att alla zoner ryms i det nätet. Den tidigare planen (zoner utspridda över 10.40.0.0/16) finns i git-historiken. Den gick inte att behålla, eftersom 10.40.2.0/24–10.40.8.0/24 tillhör andra team.

## Förutsättningar
- Teamets adressutrymme är 10.40.1.0/24 (privat enligt RFC 1918 §3, inom 10.0.0.0/8). Nätet skapas med `moln nät skapa 10.40.1.0/24`.
- Planen omfattar IPv4. IPv6 är avstängt på labbservrarna och ingår inte i planen.
- Antalet enheter per grupp bygger på antaganden om ett mellanstort företag, med 25 % tillväxt inräknad (dimensionering enligt kursens exempel).
- I varje subnät reserveras nätadressen, broadcastadressen och första användbara adressen för gateway. Användbara för enheter = 2^värdbitar − 2 − 1.
- Hetzner reserverar nätets första adress, **10.40.1.1**, som gateway för hela nätet, och i varje subnät nät- och broadcastadressen. 10.40.1.1 ligger i klientsubnätet och sammanfaller med vår gateway-regel.
- Länknäten undantas från gateway-regeln, eftersom de två adresserna där är routrarna själva. De dimensioneras som /30 eftersom vi inte vet om uppdragsgivarens routrar stödjer RFC 3021 (/31).
- Subnäten är ordnade från störst till minst så att varje prefix börjar på en jämn gräns. Oanvänt utrymme är reserverat.

## Vad som inte längre ryms

Den gamla planen behövde 276 adresser (/24 + /26 + /27 + /28 + 3 × /29 + 3 × /30), men nätet har 256. Två grupper har därför krympts:

| Grupp | Behov enligt v2 | Nu | Konsekvens |
|---|---|---|---|
| Klienter | 150 (→ /24) | /25, 125 enheter | Räcker för 100 klienter + 25 % tillväxt. Fler klienter kräver ett eget nät hos uppdragsgivaren. |
| Gäst och besök | 50 (→ /26) | /27, 29 enheter | Räcker för samtidiga gäster med kort DHCP-lån. Gästnätet når bara internet och kan vid behov flyttas helt utanför det interna nätet. |

**Behöver beslutas i teamet** innan nätet skapas på workshop 1 (onsdag 28/10).

## Adressplan

| Prefix | Syfte | Uträkning | Adressintervall för enheter (första–sista) | Ansvarig tjänst | Reserverat utrymme | Kommentar |
|---|---|---|---|---|---|---|
| 10.40.1.0/25 | Klienter | 125 → 2⁷ − 2 − 1 = 125 → /25 | 10.40.1.2 – 10.40.1.126 | Arbetsplatser (DHCP) | – | Gateway 10.40.1.1 (Hetzners nätgateway), broadcast 10.40.1.127 |
| 10.40.1.128/27 | Servrar | 18 → 2⁵ − 2 − 1 = 29 → /27 | 10.40.1.130 – 10.40.1.158 | Applikationsservrar | – | Gateway .129, broadcast .159 |
| 10.40.1.160/27 | Gäst och besök | 29 → 2⁵ − 2 − 1 = 29 → /27 | 10.40.1.162 – 10.40.1.190 | Gästnät (DHCP) | – | Gateway .161, broadcast .191 |
| 10.40.1.192/28 | Drift och administration | 8 → 2⁴ − 2 − 1 = 13 → /28 | 10.40.1.194 – 10.40.1.206 | jump (SSH 22) | – | Gateway .193, broadcast .207 |
| 10.40.1.208/29 | Databaser | 5 → 2³ − 2 − 1 = 5 → /29 | 10.40.1.210 – 10.40.1.214 | Databastjänst (TCP 5432) | – | Gateway .209, broadcast .215 |
| 10.40.1.216/29 | Logg och övervakning | 4 → 2³ − 2 − 1 = 5 → /29 | 10.40.1.218 – 10.40.1.222 | log (TCP 514 i v4, TCP 6514 med TLS från v5) | – | Gateway .217, broadcast .223 |
| 10.40.1.224/29 | DMZ | 5 → 2³ − 2 − 1 = 5 → /29 | 10.40.1.226 – 10.40.1.230 | Publik webb (HTTP 80, 443) | – | Gateway .225, broadcast .231 |
| 10.40.1.232/30 | Länknät 1 | 2 → 2² − 2 = 2 → /30 | 10.40.1.233 – 10.40.1.234 | Routing (intern gateway) | – | Broadcast .235 |
| 10.40.1.236/30 | Länknät 2 | 2 → 2² − 2 = 2 → /30 | 10.40.1.237 – 10.40.1.238 | Routing | – | Broadcast .239 |
| 10.40.1.240/30 | Länknät 3 | 2 → 2² − 2 = 2 → /30 | 10.40.1.241 – 10.40.1.242 | Routing | 10.40.1.244 – 10.40.1.255 | Broadcast .243. Det reserverade utrymmet (12 adresser) får inte tas i bruk utan att planen uppdateras |

## Realisering i labbet (Hetzner)

Bara zoner med en labbserver får ett subnät i Hetzner. Jump och loggservern ligger kvar i kursens labbnät 172.20.1.0/24, så adminzonens och loggzonens subnät finns bara i planen. Reglerna använder deras verkliga adresser (172.20.1.2 och 172.20.1.58), se [zoner-i-labbet](../vecka_04/zoner-i-labbet.md).

| Server | Zon | Subnät i Hetzner | Adress på teamnätet (eth2) |
|---|---|---|---|
| elev-09 | Klientzon | 10.40.1.0/25 | 10.40.1.10 |
| elev-24 | Serverzon | 10.40.1.128/27 | 10.40.1.130 |
| elev-38 | Databaszon | 10.40.1.208/29 | 10.40.1.210 |
| elev-46 | DMZ | 10.40.1.224/29 | 10.40.1.226 |

Kommandon (nätet skapas av **en** i teamet, subnäten av samma person, varje medlem kopplar sin egen server):

```
moln nät skapa 10.40.1.0/24
moln subnät lägg-till 10.40.1.0/25
moln subnät lägg-till 10.40.1.128/27
moln subnät lägg-till 10.40.1.208/29
moln subnät lägg-till 10.40.1.224/29
moln koppla 10.40.1.130        # elev-24, övriga enligt tabellen
```

Kontrollera efteråt med `moln status` och `ip -br addr` att servern fått rätt adress på eth2.

## Vilka subnät ska nå varandra

Tillåtna flöden (allt annat blockeras som standard). Exakta portar och riktningar finns i [flödestabellen](../vecka_03/flodestabell.md).

- Gäst och besök → endast internet
- Internet → DMZ (webbservern) (TCP 80/443)
- Klienter → Servrar (TCP 443) och internet
- DMZ (webbserver) → Servrar (TCP 8080)
- Servrar → Databaser (TCP 5432)
- Drift och administration (jump) → alla interna subnät (SSH 22)
- DMZ, Servrar, Databaser och jump → Logg och övervakning (TCP 514 i v4, TCP 6514 med TLS från v5, envägs)
- Behöriga administratörer (internet) → Drift och administration/jump (SSH 22)

Inte tillåtet:
- DMZ → Databaser direkt, all åtkomst till data går via Servrar
- Gäst och besök → interna subnät
- Logg och övervakning → andra subnät

Se zonskissen i [vecka_02](zonskiss.png).

## Metod
Den ursprungliga planen (v2) räknades för hand och kontrollerades med ipcalc på elev-46, 2026-10-14T18:55:02Z. Revisionen för teamnätet 10.40.1.0/24 är framtagen med stöd av AI (Claude). Varje subnät är kontrollerat med `ipcalc -n -b --minaddr --maxaddr -p` på elev-24, 2026-10-26T07:37:49Z: nät, broadcast och första/sista adress stämmer med tabellen för alla elva prefix.
