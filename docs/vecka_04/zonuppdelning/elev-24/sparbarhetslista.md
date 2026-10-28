# Spårbarhetslista – elev-24 (Serverzon)

Varje rad i flödestabellen som gäller elev-24, och var den är implementerad. Regelns identifierare är kommentaren i [elev-24-zon.nft](elev-24-zon.nft) eller beskrivningen i [molnbrandväggen](molnbrandvagg-elev-24.md). Rad-id (F1–F24, D1–D7) enligt [flödestabellen](../../../vecka_03/flodestabell.md).

**Loggar?** Tillåtande regler loggar inte. Allt som inte släpps av någon regel loggas av den sista regeln i kedjan (`ZON-IN-DROP` / `ZON-UT-DROP`) och skickas till loggservern (D5).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager (moln/värd) | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1/F16 | In | jump 172.20.1.2 | elev-24 | tcp/22 | Värd | `D1/F16 SSH från jump` | Nej | Utkast |
| D2 | In | ctf 172.20.1.10 | elev-24 | tcp/22 | Värd | `D2 kontroll från ctf` | Nej | Utkast |
| F22 | In | jump 172.20.1.2 | elev-24 | icmp echo-request | Värd | `F22 ping från adminzon` | Nej | Utkast |
| F8 | In | Klientzon 10.40.1.0/26 (elev-09) | elev-24 | tcp/443 | Värd | `F8 klienter till intern webbapp` | Nej | Utkast |
| F9 | In | DMZ 10.40.1.144/29 (elev-46) | elev-24 | tcp/8080 | Värd | `F9 DMZ hämtar data från appservern` | Nej | Utkast |
| F10 | Ut | elev-24 | Databaszon 10.40.1.160/29 (elev-38) | tcp/5432 | Värd | `F10 appen till databasen` | Nej | Utkast |
| D3/F18 | Ut | elev-24 | 185.12.64.1, 185.12.64.2 | udp/53, tcp/53 | Värd (molnet släpper alltid) | `D3/F18 DNS` | Nej | Utkast |
| D4/F19 | Ut | elev-24 | 213.239.239.164–.166 (ntp.hetzner.com) | udp/123 | Värd + moln | värd: `D4/F19 NTP`, moln: `F19 NTP ntp.hetzner.com (D4)` | Nej | Utkast |
| D5/F12 | Ut | elev-24 | log 172.20.1.58 | tcp/514 | Värd | `D5/F12 loggar till log (TCP 6514 med TLS från v5)` | Nej | Utkast |
| D6/F23 | Ut | elev-24 | DHCP-servrar | udp/68 → 67 | Värd (molnet släpper alltid) | `D6/F23 DHCP-förnyelse` | Nej | Utkast |
| D7/F20 | Ut | elev-24 | Internet | tcp/443 | Värd + moln | värd: `D7/F20 paketuppdateringar`, moln: `F20 paketuppdateringar dnf` | Nej | Utkast |
| Nekande | In och ut | Allt annat | – | – | Värd + moln | `policy drop` + `ZON-IN-DROP` / `ZON-UT-DROP` | Ja | Utkast |

F12 på TCP 6514 med TLS läggs till i vecka 5 och ersätter då D5. Öppningar för enskilda labbar (till exempel ctf → tcp/80) läggs bara till när labben kräver det, se [zoner-i-labbet](../../zoner-i-labbet.md).

Rader i flödestabellen som inte gäller elev-24 (t.ex. F4–F5, F11, F13) implementeras på respektive teamkamrats server.

Status ändras till **Verifierad** när raden har ett godkänt test i [testprotokollet](testprotokoll.md).
