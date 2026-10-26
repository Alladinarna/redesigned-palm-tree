# Spårbarhetslista – elev-24 (Serverzon)

Varje rad i flödestabellen som gäller elev-24, och var den är implementerad. Regelns identifierare är kommentaren i [elev-24-zon.nft](elev-24-zon.nft) eller beskrivningen i [molnbrandväggen](molnbrandvagg-elev-24.md). Rad-id enligt [flödestabellen](../../../vecka_03/flodestabell.md) och [driftflödena](../flodestabell-driftfloden.md).

**Loggar?** Tillåtande regler loggar inte. Allt som inte släpps av någon regel loggas av den sista regeln i kedjan (`ZON-IN-DROP` / `ZON-UT-DROP`) och skickas till loggservern (D5).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager (moln/värd) | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1/16 | In | jump 172.20.1.2 | elev-24 | tcp/22 | Värd | `D1/16 SSH från jump` | Nej | Utkast |
| D2 | In | ctf 172.20.1.10 | elev-24 | tcp/22 | Värd | `D2 kontroll från ctf` | Nej | Utkast |
| 22 | In | jump 172.20.1.2 | elev-24 | icmp echo-request | Värd | `22 ping från adminzon` | Nej | Utkast |
| 8 | In | Klientzon 10.40.1.0/25 | elev-24 | tcp/443 | Värd | `8 klienter till intern webbapp` | Nej | Utkast |
| 9 | In | DMZ 10.40.1.224/29 | elev-24 | tcp/8080 | Värd | `9 DMZ hämtar data från appservern` | Nej | Utkast |
| L1 | In | ctf 172.20.1.10 | elev-24 | tcp/80 | Värd | `L1 ctf testar webbservern` | Nej | Utkast |
| 10 | Ut | elev-24 | Databaszon 10.40.1.208/29 | tcp/5432 | Värd | `10 appen till databasen` | Nej | Utkast |
| 12 | Ut | elev-24 | log 172.20.1.58 | tcp/6514 | Värd | `12 loggar till log med TLS` | Nej | Utkast (används från v5) |
| D3/18 | Ut | elev-24 | 185.12.64.1, 185.12.64.2 | udp/53, tcp/53 | Värd (molnet släpper alltid) | `D3/18 DNS` | Nej | Utkast |
| D4/19 | Ut | elev-24 | Internet | udp/123 | Värd + moln | `D4/19 NTP` (båda lagren) | Nej | Utkast |
| D5 | Ut | elev-24 | log 172.20.1.58 | tcp/514 | Värd | `D5 brandväggslogg till log` | Nej | Utkast |
| D6/23 | Ut | elev-24 | DHCP-servrar | udp/68 → 67 | Värd (molnet släpper alltid) | `D6/23 DHCP-förnyelse` | Nej | Utkast |
| D7/20 | Ut | elev-24 | Internet | tcp/443 | Värd + moln | `D7/20 paketuppdateringar` (båda lagren) | Nej | Utkast |
| Nekande | In och ut | Allt annat | – | – | Värd + moln | `policy drop` + `ZON-IN-DROP` / `ZON-UT-DROP` | Ja | Utkast |

Rader i flödestabellen som inte gäller elev-24 (t.ex. 4–5, 11, 13) implementeras på respektive teamkamrats server.

Status ändras till **Verifierad** när raden har ett godkänt test i [testprotokollet](testprotokoll.md).
