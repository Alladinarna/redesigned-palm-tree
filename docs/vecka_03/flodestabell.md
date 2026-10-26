# Flödestabell: tillitsregler mellan zoner

**Värd** = nftables, eftersom trafik i det privata nätet inte passerar molnbrandväggen. **Molnbrandvägg** = trafik mot eller från internet.

| Rad | Källzon | Målzon | Protokoll | Port | Riktning | Motivering (verksamhetsfunktion) | Filtreras var (molnplattform/värd) |
|---|---|---|---|---|---|---|---|
| 1 | Gästzon | Internet | TCP | 80 (http) | Utgående | Gäster surfar på webben | Molnbrandvägg, trafik mot internet |
| 2 | Gästzon | Internet | TCP | 443 (https) | Utgående | Gäster surfar på webben | Molnbrandvägg, trafik mot internet |
| 3 | Gästzon | Internet (extern DNS) | UDP | 53 | Utgående | Namnuppslag så att webben fungerar | Molnbrandvägg, trafik mot internet |
| 4 | Internet | DMZ (publik webb) | TCP | 80 (http) | Inkommande | För att trafik ska nå företagets webb | Molnbrandvägg, trafik från internet |
| 5 | Internet | DMZ (publik webb) | TCP | 443 (https) | Inkommande | För att trafik ska nå företagets webb | Molnbrandvägg, trafik från internet |
| 6 | Klientzon | Internet | TCP | 80, 443 | Utgående | Anställda når webb- och molntjänster (http, https) | Molnbrandvägg, trafik mot internet |
| 7 | Klientzon | Hetzners DNS-resolvrar 185.12.64.1, 185.12.64.2 | UDP, TCP | 53 | Utgående | Namnuppslag så att webben fungerar. TCP behövs för stora svar | Värd (nftables). Molnbrandväggen släpper alltid Hetzners DNS |
| 8 | Klientzon | Serverzon | TCP | 443 | Envägs | Anställda använder företagets interna webbapplikationer via https | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 9 | DMZ | Serverzon | TCP | 8080 | Envägs | Den publika webben hämtar data från applikationsservern | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 10 | Serverzon | Databaszon | TCP | 5432 | Envägs | Applikationen läser och skriver data i databasen | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 11 | DMZ | Loggzon | TCP | 6514 | Envägs | DMZ skickar webb- och säkerhetsloggar till loggservern för spårbarhet vid incidenter | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 12 | Serverzon | Loggzon | TCP | 6514 | Envägs | Applikationsservrarna skickar loggar till loggservern för spårbarhet vid incidenter | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 13 | Databaszon | Loggzon | TCP | 6514 | Envägs | Databasen skickar loggar till loggservern för spårbarhet vid incidenter | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 14 | Adminzon | Loggzon | TCP | 6514 | Envägs | Jump skickar loggar över administrativa inloggningar till loggservern | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 15 | Internet (behörig administratör) | Adminzon | TCP | 22 | Inkommande | Administratörer loggar in på jump med nyckel och MFA, från begränsade källadresser | Molnbrandvägg, trafik från internet |
| 16 | Adminzon | Alla interna zoner utom Loggzon (Gäst, Klient, DMZ, Server, Databas, Infrastruktur) | TCP | 22 | Envägs | Administration av servrar och utrustning. Accepterad risk, se markeringstabellen | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 17 | Adminzon | Loggzon | TCP | 22 | Envägs | Loggadministration, endast med separat loggadmin-konto | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 18 | Alla serverzoner (DMZ, Server, Databas, Logg, Admin) | Hetzners DNS-resolvrar 185.12.64.1, 185.12.64.2 | UDP, TCP | 53 | Utgående | Namnuppslag. TCP behövs för stora svar | Värd (nftables). Molnbrandväggen släpper alltid Hetzners DNS |
| 19 | Alla serverzoner, Klientzon och Infrastruktur | Internet (NTP) | UDP | 123 | Utgående | Korrekt tid för loggar, inloggningar och certifikat | Molnbrandvägg, trafik mot internet |
| 20 | Alla serverzoner | Internet (paketförråd) | TCP | 443 | Utgående | Säkerhetsuppdateringar via dnf | Molnbrandvägg, trafik mot internet |
| 21 | Infrastruktur | Loggzon | TCP | 6514 | Envägs | Routrarna skickar loggar till loggservern för spårbarhet vid incidenter | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 22 | Adminzon | Alla interna zoner | ICMP | – (echo) | Envägs | Felsökning, att kunna kontrollera om en enhet går att nå | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 23 | Alla serverzoner och Klientzon | DHCP-servrarna: 172.31.1.1 (eth0), 172.20.0.1 (eth1), 10.40.1.1 (eth2) | UDP | 68 → 67 | Utgående | Servrarna får och förnyar sina adresser via DHCP på alla tre gränssnitt | Värd (nftables), måste tillåtas så att servern behåller sin adress |
| 24 | ctf-servern 172.20.1.10 (kursens kontrolltjänst) | Alla labbservrar | TCP | 22, 80 | Inkommande | Kursens kontroller loggar in och testar webbservern. Gäller bara labbet, se zoner-i-labbet | Värd (nftables), labbnätet passerar inte molnbrandväggen |
| 25 | Alla labbservrar | Loggzon (log 172.20.1.58) | TCP | 514 | Envägs | Brandväggsloggen skickas till loggservern i klartext under vecka 4. Ersätts av rad 11–14 (TCP 6514 med TLS) i vecka 5 | Värd (nftables), privat nät som inte passerar molnbrandväggen |

Rad 7, 18, 23 och 24–25 är ändrade eller tillagda i vecka 4 (2026-10-26) utifrån driftflödena D1–D7 i studieguiden, se [flodestabell-driftfloden](../vecka_04/zonuppdelning/flodestabell-driftfloden.md). Zonernas adresser finns i [adressplanen](../vecka_02/adressplan.md) och [zoner-i-labbet](../vecka_04/zoner-i-labbet.md).

**Nekanderegel:** Allt som inte står ovan är nekat, inkommande och utgående, i både molnbrandväggen och värdbrandväggen.

## Jämförelse med trafikbaslinjen (vecka 1)

| Flöde i baslinjen | I flödestabellen? | Beslut |
|---|---|---|
| SSH från jump till server, TCP 22 | Ja, rad 16 | Tillåts |
| DNS till 185.12.64.1, UDP 53 | Ja, rad 18 | Tillåts |
| NTP till 185.12.64.2, UDP 123 | Ja, rad 19 | Tillåts |
| ICMP echo från loggservern | Delvis, rad 22 | Tillåts bara från Adminzon för felsökning |
| HTTP till loggserverns testtjänst, TCP 80 | Nej | Nekas. Testtjänst för kursens labbar, ingen verksamhetsfunktion. Loggar skickas på TCP 6514 |
| UDP 901–904 från ctf-servern | Nej | Nekas i designen. Kursens labbtrafik, se zoner-i-labbet.md |
| TCP 9000 till loggservern | Nej | Nekas. Labbtrafik utan verksamhetsfunktion |
| TCP 4444 till 203.0.113.230 (avvikelse) | Nej | Nekas av nekanderegeln. Porten används ofta för bakdörrar där en kapad server kopplar upp sig mot angriparen, vilket visar varför utgående trafik också måste nekas |
