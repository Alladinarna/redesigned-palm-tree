# Tillgångsförteckning - zonuppdraget

Förteckningen beskriver labbmiljön som den ser ut idag.

## Nätet 
Labbnätet är 172.20.0.0/16 med gateway på 172.20.0.1 (eth1).
Interfacen har /32 så servrarna har inget delat länknät, all intern trafik passerar gatewayen. Mot internet går eth0 via 172.31.1.1 med publik adress satt via DHCP. IPV6 saknar adresser på interfacen men sshd och chronyd har ändå IPV6 sockets öppna.
Belägg: ip route, ip -br addr på elev-46, 11:50Z 2026-10-13.

## Infrastruktur 
| Namn | Roll | intern Adress | publik Adress | Tjänster | Belägg | Zon |
|---|---|---|---|---|---|---|
| jump | Bastion, enda vägen in till servrarna | 172.20.1.2 | 2.28.140.211 | SSH 22 | getent hosts 2026-10-13 | Adminzon |
| log | Central loggmottagare och testtjänst | 172.20.1.58 | 46.224.108.117 | TCP 514, HTTP | getent hosts 2026-10-13 | Logzon |
| ctf | Kursens CTF-server. Tar emot och kontrollerar flaggor. Används via kommandon på jump (ctf-status, kontrollera, lämna-flagga). | 172.20.1.10 | 46.224.130.227 | HTTP | getent hosts 2026-10-13 | Utanför uppdraget, kursens infrastruktur |
| Intern gateway | Router för labbnätet | 172.20.0.1 | — | Routing | ip route 11:50Z 2026-10-13 | Länk-nät |
| Extern gateway | Väg mot internet, DHCP | 172.31.1.1 | — | DHCP 67, routing | ip route 11:50Z 2026-10-13 | - |
| DNS | Namnuppslag för externa namn och kursens zon | 185.12.64.1, 185.12.64.2 | — | DNS 53 | /etc/resolv.conf 11:50Z 2026-10-13 | - |

## Våra servrar

Alla fyra servrar kör Rocky linux 9 med samma grunduppsättning, webbserver och SSH nås bara via jump servern. eth1 mot labbnätet och eth0 mot internet.
chronyd och dhclient körs också men är klienter, inte tjänster som andra kan nå.

| Elev | intern Adress | publik Adress | Tjänster | Belägg | Zon |
|---|---|---|---|---|---|
| elev-46 | 172.20.1.146/32 | 46.224.175.57/32 | SSH 22, HTTP 80 | ip -br addr, ip route, ss -tulnp, getent hosts 13:32Z 2026-10-13 | Serverzon |
| elev-24 | 172.20.1.124/32 | 91.99.144.137/32 | SSH 22, HTTP 80 | ip -br addr, ip route, ss -tulnp, getent hosts 16:15Z 2026-10-13 | Serverzon |
| elev-38 | 172.20.1.138/32 | 91.107.220.202/32 | SSH 22, HTTP 80 | ip -br addr, ip route, ss -tulnp, getent hosts 16:45Z 2026-10-13| Serverzon |
| elev-09 | 172.20.1.109/32 | 2.28.105.6/32 | SSH 22, HTTP 80 | ip -br addr, ip route, ss -tulnp, getent hosts 15:57Z 2026-10-13 | Serverzon |

# Klassifiering

| Zon | Känslighet (C, I) | Driftkritikalitet (A) |
|---|---|---|
| Klientzon | Medel, på arbetsdatorerna finns mejl, dokument och inloggningar. Kommer någon obehörig åt dem kan de läsa eller ändra information, men det drabbar främst enskilda användare. | Medel, arbetseffektiviteten kan bli påverkad men förmodligen kan arbetet fortgå. |
| Gästzon | Låg, gäster ska bara nå internet och ingen av företagets information finns i zonen. | Låg, nätverk för gäster är ett plus men påverkar inte driften. |
| Loggzon | Hög, om obehöriga kan läsa eller ändra loggarna går de inte att lita på och det blir svårt att utreda incidenter. | Medel, verksamheten kan fortsätta utan loggservern men under tiden finns ingen spårning på vem som gjort vad. |
| Serverzon (applikation) | Hög, applikationerna hanterar viktig data och har åtkomst till databasen. Kommer obehöriga åt dem kan data läsas eller ändras. | Hög, utan applikationsservern kan verksamheten påverkas och i värsta fall inte fungera. |
| Databaszon | Hög, kommer obehöriga åt databasen kommer de åt hela företagets information inklusive kunduppgifter, vilket kan bryta mot flera lagar och ge böter och ekonomiska förluster. | Hög, slutar databasen fungera kan applikationsservern inte hämta data och tjänsterna som bygger på den slutar fungera. Nätverket påverkas inte, men verksamheten gör det. |
| Adminzon | Hög, jump har behörighet till alla interna zoner. Kommer obehöriga åt den har de vägar in till hela företagets infrastruktur. | Hög, jump används för administrativ åtkomst. Slutar den fungera kan admin inte komma åt servrarna, exempelvis för att felsöka. |
| DMZ (publik webb) | Medel, webbsidan är publik så det gör inget om den läses. Men ändrar någon den syns det för alla besökare. | Medel, webbplatsen slutar fungera men de interna servrarna fortsätter fungera. |
| Länknät | Hög, kommer någon obehörig åt routrarna kan den manipulera och dirigera om nätverkstrafiken. | Hög, länknäten kopplar ihop routrarna. Slutar ett länknät fungera kan kommunikationen mellan zonerna påverkas och vissa tjänster bli otillgängliga. |
## Observationer 
- sshd och httpd lyssnar på 0.0.0.0 alltså även publikt. Enligt kursinstruktionen är SSH ändå stängt från internet.
- Varje värd har två adresser. Kortnamnet i /etc/hosts pekar på den interna medans DNS zonern sec.chas-lab.dev publicerar den publika.
- Jump har en publik adress i ett annat block (2.28.140) än log, ctf och elev-46 som alla ligger i 46.224. Vi vet inte varför.
- DNS-resolvrarna är publika adresser. DNS-trafiken lämnar labbnätet via eth0.
