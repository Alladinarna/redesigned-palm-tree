# Spårbarhetslista – elev-46 (DMZ)

Varje rad i flödestabellen som gäller elev-46, och var den är implementerad. Regelns identifierare är kommentaren i [elev-46-zon.nft](elev-46-zon.nft) eller beskrivningen i [molnbrandväggen](molnbrandvagg-elev-46.md). Rad-id (F1–F24, D1–D7) enligt [flödestabellen](../../../vecka_03/flodestabell.md).

**Loggar?** Tillåtande regler loggar inte. Allt som inte släpps av någon regel loggas av den sista regeln i kedjan (`ZON-IN-DROP` / `ZON-UT-DROP`) och skickas till loggservern (D5).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager (moln/värd) | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1/F16 | In | jump 172.20.1.2 | elev-46 | tcp/22 | Värd | `D1/F16 SSH från jump` | Nej | Utkast |
| D2 | In | ctf 172.20.1.10 | elev-46 | tcp/22 | Värd | `D2 kontroll från ctf` | Nej | Utkast |
| F22 | In | jump 172.20.1.2 | elev-46 | icmp echo-request | Värd | `F22 ping från adminzon` | Nej | Utkast |
| F4 | In | Internet | elev-46 | tcp/80 | Moln + värd | moln: `F4 webb http från internet`, värd: `F4/F5 webb från internet` | Nej | Utkast |
| F5 | In | Internet | elev-46 | tcp/443 | Moln + värd | moln: `F5 webb https från internet`, värd: `F4/F5 webb från internet` | Nej | Utkast |
| F9 | Ut | elev-46 | Serverzon 10.40.1.96/27 | tcp/8080 | Värd | `F9 DMZ hämtar data från appservern` | Nej | Utkast |
| D3/F18 | Ut | elev-46 | 185.12.64.1, 185.12.64.2 | udp/53, tcp/53 | Värd (molnet släpper alltid) | `D3/F18 DNS` | Nej | Utkast |
| D4/F19 | Ut | elev-46 | 213.239.239.164–.166 (ntp.hetzner.com) | udp/123 | Värd + moln | värd: `D4/F19 NTP`, moln: `F19 NTP ntp.hetzner.com (D4)` | Nej | Utkast |
| D5/F11 | Ut | elev-46 | log 172.20.1.58 | tcp/514 | Värd | `D5/F11 loggar till log (TCP 6514 med TLS från v5)` | Nej | Utkast |
| D6/F23 | Ut | elev-46 | DHCP-servrar | udp/68 → 67 | Värd (molnet släpper alltid) | `D6/F23 DHCP-förnyelse` | Nej | Utkast |
| D7/F20 | Ut | elev-46 | Internet | tcp/443 | Värd + moln | värd: `D7/F20 paketuppdateringar`, moln: `F20 paketuppdateringar dnf (D7)` | Nej | Utkast |
| Nekande | In och ut | Allt annat | – | – | Värd + moln | `policy drop` + `ZON-IN-DROP` / `ZON-UT-DROP` | Ja | Utkast |

Värdregeln för F4–F5 gäller bara trafik in på eth0 (från internet). Webbservern nås alltså inte från labbnätet eller teamnätet.

F11 på TCP 6514 med TLS läggs till i vecka 5 och ersätter då D5. Fram till dess nekas tcp/6514 (testfall F11-nek-v4).

Ingen generell öppning för ctf → tcp/80. Regeln (L1) fanns för U3.4, som är stängd, och står inte i flödestabellen. Öppningar för enskilda labbar läggs bara till när en labb kräver det, se [zoner-i-labbet](../../zoner-i-labbet.md).

Status ändras till **Verifierad** när raden har ett godkänt test i [testprotokollet](testprotokoll.md).
