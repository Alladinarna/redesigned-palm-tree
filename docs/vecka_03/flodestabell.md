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
| 7 | Klientzon | Internet (extern DNS) | UDP | 53 | Utgående | Namnuppslag så att webben fungerar | Molnbrandvägg, trafik mot internet |
| 8 | Klientzon | Serverzon | TCP | 443,8080 | Envägs | Anställda använder företagets applikationer | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 9 | DMZ | Serverzon | TCP | 8080 | Envägs | Den publika webben hämtar data från applikationsservern | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 10 | Serverzon | Databaszon | TCP | 5432 | Envägs | Applikationen läser och skriver data i databasen | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 11 | DMZ | Loggzon | TCP | 6514 | Envägs | DMZ skickar webb- och säkerhetsloggar till loggservern för spårbarhet vid incidenter | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 12 | Serverzon | Loggzon | TCP | 6514 | Envägs | Applikationsservrarna skickar loggar till loggservern för spårbarhet vid incidenter | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 13 | Databaszon | Loggzon | TCP | 6514 | Envägs | Databasen skickar loggar till loggservern för spårbarhet vid incidenter | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 14 | Adminzon | Loggzon | TCP | 6514 | Envägs | Jump skickar loggar över administrativa inloggningar till loggservern | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 15 | Internet (behörig administratör) | Adminzon | TCP | 22 | Inkommande | Administratörer loggar in på jump med nyckel och MFA, från begränsade källadresser | Molnbrandvägg, trafik från internet |
| 16 | Adminzon | Alla interna zoner utom Loggzon (Gäst, Klient, DMZ, Server, Databas, Infrastruktur) | TCP | 22 | Envägs | Administration av servrar och utrustning. Accepterad risk, se markeringstabellen | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 17 | Adminzon | Loggzon | TCP | 22 | Envägs | Loggadministration, endast med separat loggadmin-konto | Värd (nftables), privat nät som inte passerar molnbrandväggen |
| 18 | Alla serverzoner (DMZ, Server, Databas, Logg, Admin) | Internet (extern DNS) | UDP | 53 | Utgående | Namnuppslag | Molnbrandvägg, trafik mot internet |
| 19 | Alla serverzoner | Internet (NTP) | UDP | 123 | Utgående | Korrekt tid för loggar och certifikat | Molnbrandvägg, trafik mot internet |
| 20 | Alla serverzoner | Internet (paketförråd) | TCP | 443 | Utgående | Säkerhetsuppdateringar via dnf | Molnbrandvägg, trafik mot internet |

**Nekanderegel:** Allt som inte står ovan är nekat, inkommande och utgående, i både molnbrandväggen och värdbrandväggen.
