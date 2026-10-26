# Spårbarhetslista – elev-09 (Klientzon)

Varje rad i flödestabellen som gäller elev-09, och var den är implementerad. Regelns identifierare är kommentaren i [elev-09-zon.nft](elev-09-zon.nft) eller beskrivningen i [molnbrandväggen](molnbrandvagg-elev-09.md). Rad-id enligt [flödestabellen](../../../vecka_03/flodestabell.md) och [driftflödena](../flodestabell-driftfloden.md).

**Loggar?** Tillåtande regler loggar inte. Allt som inte släpps av någon regel loggas av den sista regeln i kedjan (`ZON-IN-DROP` / `ZON-UT-DROP`) och skickas till loggservern (D5).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager (moln/värd) | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1/16 | In | jump 172.20.1.2 | elev-09 | tcp/22 | Värd | `D1/16 SSH från jump` | Nej | Utkast |
| D2 | In | ctf 172.20.1.10 | elev-09 | tcp/22 | Värd | `D2 kontroll från ctf` | Nej | Utkast |
| 22 | In | jump 172.20.1.2 | elev-09 | icmp echo-request | Värd | `22 ping från adminzon` | Nej | Utkast |
| L1 | In | ctf 172.20.1.10 | elev-09 | tcp/80 | Värd | `L1 ctf testar webbservern` | Nej | Utkast |
| 8 | Ut | elev-09 | Serverzon 10.40.1.96/27 | tcp/443 | Värd | `8 klienter till intern webbapp` | Nej | Utkast |
| 6 | Ut | elev-09 | Internet | tcp/80, tcp/443 | Värd + moln | `6/D7 webb och paketuppdateringar`, moln: `6 webb (http)`, `6/D7 webb (https) …` | Nej | Utkast |
| D3/7 | Ut | elev-09 | 185.12.64.1, 185.12.64.2 | udp/53, tcp/53 | Värd (molnet släpper alltid) | `D3/7 DNS` | Nej | Utkast |
| D4/19 | Ut | elev-09 | Internet | udp/123 | Värd + moln | `D4/19 NTP` (båda lagren) | Nej | Utkast |
| D5 | Ut | elev-09 | log 172.20.1.58 | tcp/514 | Värd | `D5 brandväggslogg till log` | Nej | Utkast |
| D6/23 | Ut | elev-09 | DHCP-servrar | udp/68 → 67 | Värd (molnet släpper alltid) | `D6/23 DHCP-förnyelse` | Nej | Utkast |
| D7 | Ut | elev-09 | Internet | tcp/443 | Värd + moln | Täcks av rad 6 | Nej | Utkast |
| Nekande | In och ut | Allt annat | – | – | Värd + moln | `policy drop` + `ZON-IN-DROP` / `ZON-UT-DROP` | Ja | Utkast |

Klientzonen har ingen loggrad till loggservern med TLS i flödestabellen (rad 11–14 gäller DMZ, Server, Databas och Admin). Brandväggsloggen skickas ändå enligt D5.

Status ändras till **Verifierad** när raden har ett godkänt test i [testprotokollet](testprotokoll.md).
