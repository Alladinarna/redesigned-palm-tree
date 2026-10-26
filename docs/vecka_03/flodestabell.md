# Flödestabell: tillitsregler mellan zoner
 
Prefixen kommer från adressplanen ([adressplan.md](../vecka_02/adressplan.md)). Varje rad har ett id (F1, F2 …) som återkommer i kommentaren till nftables-regeln och i beskrivningen av molnregeln.
 
**Riktning** anges sett från den server regeln ligger på. **Ut** och **In** gäller trafik mot eller från internet. **Intern** betyder att flödet går mellan två zoner och blir två regler: en i kedjan ut på källservern och en i kedjan in på målservern.
 
**Lager:**
- **Värd** = nftables. All trafik filtreras här. Bara här kan vi skriva egna nekande regler, välja mellan tyst drop och avvisning, och logga nekad trafik.
- **Molnbrandvägg** = Hetzners brandvägg, som bara ser det publika gränssnittet (eth0). Reglerna anger bara vad som tillåts. Allt annat blockeras av ett implicit deny i slutet.
- Trafik i det privata nätet (eth1 och eth2) passerar inte molnbrandväggen och filtreras bara på värden.
## Tillåtna flöden
 
| Rad | Källzon | Målzon | Protokoll | Port | Riktning | Motivering (verksamhetsfunktion) | Lager |
|---|---|---|---|---|---|---|---|
| F1 | Gästzon (10.40.1.64/27) | Internet | TCP | 80 (http) | Ut | Gäster surfar på webben | Värd och molnbrandvägg |
| F2 | Gästzon (10.40.1.64/27) | Internet | TCP | 443 (https) | Ut | Gäster surfar på webben | Värd och molnbrandvägg |
| F3 | Gästzon (10.40.1.64/27) | Resolvrarna som DHCP delar ut (antagande: Hetzners 185.12.64.1 och 185.12.64.2) | UDP och TCP | 53 | Ut | Namnuppslag så att webben fungerar. TCP behövs när svaret är för stort för UDP | Värd (molnbrandväggen släpper alltid Hetzners resolvrar) |
| F4 | Internet | DMZ (10.40.1.144/29) | TCP | 80 (http) | In | För att trafik ska nå företagets webb | Molnbrandvägg och värd |
| F5 | Internet | DMZ (10.40.1.144/29) | TCP | 443 (https) | In | För att trafik ska nå företagets webb | Molnbrandvägg och värd |
| F6 | Klientzon (10.40.1.0/26) | Internet | TCP | 80, 443 | Ut | Anställda når webb- och molntjänster (http, https) | Värd och molnbrandvägg |
| F7 | Klientzon (10.40.1.0/26) | Resolvrarna som DHCP delar ut (antagande: Hetzners 185.12.64.1 och 185.12.64.2) | UDP och TCP | 53 | Ut | Namnuppslag så att webben fungerar. TCP behövs när svaret är för stort för UDP | Värd (molnbrandväggen släpper alltid Hetzners resolvrar) |
| F8 | Klientzon (10.40.1.0/26) | Serverzon (10.40.1.96/27) | TCP | 443 | Intern | Anställda använder företagets interna webbapplikationer via https | Värd |
| F9 | DMZ (10.40.1.144/29) | Serverzon (10.40.1.96/27) | TCP | 8080 | Intern | Den publika webben hämtar data från applikationsservern | Värd |
| F10 | Serverzon (10.40.1.96/27) | Databaszon (10.40.1.160/29) | TCP | 5432 | Intern | Applikationen läser och skriver data i databasen | Värd |
| F11 | DMZ (10.40.1.144/29) | Loggzon (10.40.1.152/29) | TCP | 6514 (TLS) | Intern | DMZ skickar webb- och säkerhetsloggar till loggservern för spårbarhet vid incidenter | Värd |
| F12 | Serverzon (10.40.1.96/27) | Loggzon (10.40.1.152/29) | TCP | 6514 (TLS) | Intern | Applikationsservrarna skickar loggar till loggservern för spårbarhet vid incidenter | Värd |
| F13 | Databaszon (10.40.1.160/29) | Loggzon (10.40.1.152/29) | TCP | 6514 (TLS) | Intern | Databasen skickar loggar till loggservern för spårbarhet vid incidenter | Värd |
| F14 | Adminzon (10.40.1.128/28) | Loggzon (10.40.1.152/29) | TCP | 6514 (TLS) | Intern | Jump skickar loggar över administrativa inloggningar till loggservern | Värd |
| F15 | Internet (behörig administratör, begränsade källadresser) | Adminzon (10.40.1.128/28) | TCP | 22 | In | Administratörer loggar in på jump med nyckel och MFA | Molnbrandvägg och värd |
| F16 | Adminzon (10.40.1.128/28) | Gästzon (10.40.1.64/27), Klientzon (10.40.1.0/26), DMZ (10.40.1.144/29), Serverzon (10.40.1.96/27), Databaszon (10.40.1.160/29), Infrastruktur (10.40.1.240–.251) | TCP | 22 | Intern | Administration av servrar och utrustning. Accepterad risk, se [markeringstabell.md](markeringstabell.md) | Värd |
| F17 | Adminzon (10.40.1.128/28) | Loggzon (10.40.1.152/29) | TCP | 22 | Intern | Loggadministration, endast med separat loggadmin-konto | Värd |
| F18 | Alla serverzoner (DMZ, Server, Databas, Logg, Admin) | Hetzners DNS-resolvrar 185.12.64.1 och 185.12.64.2 | UDP och TCP | 53 | Ut | Namnuppslag | Värd (molnbrandväggen släpper alltid Hetzners resolvrar) |
| F19 | Alla serverzoner, Klientzon och Infrastruktur | Hetzners NTP-servrar (ntp.hetzner.com: 213.239.239.164, 213.239.239.165, 213.239.239.166) | UDP | 123 | Ut | Korrekt tid för loggar, inloggningar och certifikat | Värd och molnbrandvägg |
| F20 | Alla serverzoner | Internet (paketförråd) | TCP | 443 | Ut | Säkerhetsuppdateringar via dnf | Värd och molnbrandvägg |
| F21 | Infrastruktur (10.40.1.240–.251) | Loggzon (10.40.1.152/29) | TCP | 6514 (TLS) | Intern | Routrarna skickar loggar till loggservern för spårbarhet vid incidenter | Värd |
| F22 | Adminzon (10.40.1.128/28) | Samma zoner som F16 (inte Loggzon) | ICMP | echo-request | Intern | Felsökning, att kunna kontrollera om en enhet går att nå | Värd |
| F23 | Alla serverzoner | DHCP-servern | UDP | 68 → 67 | Ut | Servrarna förnyar sina adresser på alla nätkort. Utan regeln tappar servern adresserna när lånet går ut | Värd (molnbrandväggen släpper alltid DHCP) |
 
**Nekanderegel:** Allt som inte står ovan nekas, inkommande och utgående.
- **På värden:** policy drop i både kedjan in och kedjan ut, med en loggregel sist i varje kedja.
- **I molnbrandväggen:** inkommande trafik nekas om den inte är uttryckligen tillåten. Utgående trafik nekas så snart den första utgående regeln finns. Därför skrivs alla utgående rader mot internet även som molnregler.
Påståendena om molnbrandväggen bygger på Hetzners dokumentation, se Källor längst ned.
 
## Realisering i labbet
 
### Driftflöden
 
Driftflödena är det varje teamserver (elev-46, elev-24, elev-38 och elev-09) själv behöver i labbet. Jump och log ligger i labbnätet 172.20.1.0/24, så här används deras verkliga adresser.
 
| Rad | Riktning | Källa → mål | Protokoll/port | Varför | Realiserar | Lager |
|---|---|---|---|---|---|---|
| D1 | In | jump 172.20.1.2 → min server | TCP 22 | Administration via jump | F16 | Värd |
| D2 | In | ctf 172.20.1.10 → min server | TCP 22 | Kursens kontrolltjänst. Utan den kommer CTF-kontrollerna inte in | – (labbet) | Värd |
| D3 | Ut | min server → 185.12.64.1 och 185.12.64.2 | UDP och TCP 53 | Namnuppslag | F18 | Värd |
| D4 | Ut | min server → 213.239.239.164, 213.239.239.165, 213.239.239.166 (ntp.hetzner.com) | UDP 123 | Tidssynk (chrony är konfigurerad med `server ntp.hetzner.com`). Slutar tidssynken fungera kontrolleras adresserna med `getent ahostsv4 ntp.hetzner.com` | F19 | Värd och molnbrandvägg |
| D5 | Ut | min server → log 172.20.1.58 | TCP 514 | Brandväggsloggen till loggservern. Klartext i vecka 4, TCP 6514 med TLS från vecka 5 | F11–F14 | Värd |
| D6 | Ut | min server → DHCP-servern (172.31.1.1 på eth0, 172.20.0.1 på eth1, 10.40.1.1 på eth2) | UDP 68 → 67 | Förnyelse av serverns adresser | F23 | Värd |
| D7 | Ut | min server → internet | TCP 443 | Paketuppdateringar (dnf) | F20 | Värd och molnbrandvägg |
 
### Interna flöden mellan teamservrarna
 
Flödena går på teamnätet (eth2). Adresserna följer adressplanen.
 
| Rad | Källa | Mål | Port | Regel i kedjan ut på | Regel i kedjan in på |
|---|---|---|---|---|---|
| F8 | elev-09 (10.40.1.2) | elev-24 (10.40.1.98) | TCP 443 | elev-09 | elev-24 |
| F9 | elev-46 (10.40.1.146) | elev-24 (10.40.1.98) | TCP 8080 | elev-46 | elev-24 |
| F10 | elev-24 (10.40.1.98) | elev-38 (10.40.1.162) | TCP 5432 | elev-24 | elev-38 |
 
F15 realiseras inte i labbet. Kursens regel stänger SSH från internet, och jump är kursens server.
 
## Jämförelse med trafikbaslinjen (vecka 1)
 
| Flöde i baslinjen | I flödestabellen? | Beslut |
|---|---|---|
| SSH från jump till server, TCP 22 | Ja, F16 och D1 | Tillåts |
| DNS till 185.12.64.1, UDP 53 | Ja, F18 och D3 | Tillåts |
| NTP till ntp.hetzner.com (213.239.239.164–.166), UDP 123 | Ja, F19 och D4 | Tillåts. Verifierat på elev-46 26/10 med `chronyc -n sources` och `getent` |
| ICMP echo från loggservern | Delvis, F22 | Tillåts bara från Adminzon för felsökning |
| HTTP till loggserverns testtjänst, TCP 80 | Nej | Nekas. Testtjänst för kursens labbar, ingen verksamhetsfunktion. Loggar skickas på TCP 6514 (TCP 514 i vecka 4, D5) |
| UDP 901–904 från ctf-servern | Nej | Nekas i designen. Kursens labbtrafik, se [zoner-i-labbet.md](../vecka_04/zoner-i-labbet.md) |
| TCP 9000 till loggservern | Nej | Nekas. Labbtrafik utan verksamhetsfunktion |
| TCP 4444 till 203.0.113.230 (avvikelse) | Nej | Nekas av nekanderegeln. Porten används ofta för bakdörrar där en kapad server kopplar upp sig mot angriparen, vilket visar varför utgående trafik också måste nekas |
 
## Källor
 
1. Hetzner, Cloud Firewalls – FAQ: https://docs.hetzner.com/cloud/firewalls/faq/ – implicit deny för inkommande trafik, att utgående trafik blir implicit deny när den första utgående regeln finns, att brandväggen är stateful och att trafik mot Hetzners DNS-resolvrar alltid släpps.
2. Hetzner, Networks – FAQ: https://docs.hetzner.com/networking/networks/faq – privata nät, gateway och adresser.
3. ITSX26 kurs 2, Studieguide vecka 4, *Segmentering i drift* – att molnbrandväggen bara filtrerar det publika gränssnittet, att DHCP alltid släpps (hänvisar till Hetzners FAQ-fråga *To which traffic does the firewall apply?*) och driftflödena D1–D7.
