# Spårbarhetslista – elev-09 (Klientzon)

Varje rad i flödestabellen som gäller elev-09, och var den är implementerad. Regelns identifierare är kommentaren i [elev-09-zon.nft](elev-09-zon.nft) eller beskrivningen i [molnbrandväggen](molnbrandvagg-elev-09.md). Rad-id (F1–F24, D1–D7) enligt [flödestabellen](../../../vecka_03/flodestabell.md).

**Loggar?** Tillåtande regler loggar inte. Allt som inte släpps av någon regel loggas av den sista regeln i kedjan (`ZON-IN-DROP` / `ZON-UT-DROP`) och skickas till loggservern (D5).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager (moln/värd) | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1/F16 | In | jump 172.20.1.2 | elev-09 | tcp/22 | Värd | `D1/F16 SSH från jump` | Nej | Utkast |
| D2 | In | ctf 172.20.1.10 | elev-09 | tcp/22 | Värd | `D2 kontroll från ctf` | Nej | Utkast |
| F22 | In | jump 172.20.1.2 | elev-09 | icmp echo-request | Värd | `F22 ping från adminzon` | Nej | Utkast |
| F8 | Ut | elev-09 | Serverzon 10.40.1.96/27 | tcp/443 | Värd | `F8 klienter till intern webbapp` | Nej | Utkast |
| F6 | Ut | elev-09 | Internet | tcp/80, tcp/443 | Värd + moln | värd: `F6/D7 webb och paketuppdateringar`, moln: `F6 webb http`, `F6 webb https och paketuppdateringar (D7)` | Nej | Utkast |
| D3/F7 | Ut | elev-09 | 185.12.64.1, 185.12.64.2 | udp/53, tcp/53 | Värd (molnet släpper alltid) | `D3/F7 DNS` | Nej | Utkast |
| D4/F19 | Ut | elev-09 | 213.239.239.164–.166 (ntp.hetzner.com) | udp/123 | Värd + moln | värd: `D4/F19 NTP`, moln: `F19 NTP ntp.hetzner.com (D4)` | Nej | Utkast |
| D5 | Ut | elev-09 | log 172.20.1.58 | tcp/514 | Värd | `D5 brandväggslogg till log` | Nej | Utkast |
| D6/F23 | Ut | elev-09 | DHCP-servrar | udp/68 → 67 | Värd (molnet släpper alltid) | `D6/F23 DHCP-förnyelse` | Nej | Utkast |
| D7 | Ut | elev-09 | Internet | tcp/443 | Värd + moln | Täcks av F6 | Nej | Utkast |
| Nekande | In och ut | Allt annat | – | – | Värd + moln | `policy drop` + `ZON-IN-DROP` / `ZON-UT-DROP` | Ja | Utkast |

Klientzonen har ingen loggrad till loggservern i flödestabellen (F11–F14 gäller DMZ, Server, Databas och Admin). Brandväggsloggen skickas ändå enligt D5.

Ingen generell öppning för ctf → tcp/80. Regeln (L1) fanns för U3.4, som är stängd, och står inte i flödestabellen. Öppningar för enskilda labbar läggs bara till när en labb kräver det, se [zoner-i-labbet](../../zoner-i-labbet.md).

Status ändras till **Verifierad** när raden har ett godkänt test i [testprotokollet](testprotokoll.md).
