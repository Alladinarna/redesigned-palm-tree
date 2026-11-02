# Spårbarhetslista – elev-38 (Databaszon)

Varje rad i flödestabellen som gäller elev-38, och var den är implementerad. Regelns identifierare är kommentaren i [elev-38-zon.nft](elev-38-zon.nft) eller beskrivningen i [molnbrandväggen](molnbrandvagg-elev-38.md). Rad-id (F1–F24, D1–D7) enligt [flödestabellen](../../../vecka_03/flodestabell.md).

**Loggar?** Tillåtande regler loggar inte. Allt som inte släpps av någon regel loggas av den sista regeln i kedjan (`ZON-IN-DROP` / `ZON-UT-DROP`) och skickas till loggservern (D5).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager (moln/värd) | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1/F16 | In | jump 172.20.1.2 | elev-38 | tcp/22 | Värd | `D1/F16 SSH från jump` | Nej | Utkast |
| D2 | In | ctf 172.20.1.10 | elev-38 | tcp/22 | Värd | `D2 kontroll från ctf` | Nej | Utkast |
| F22 | In | jump 172.20.1.2 | elev-38 | icmp echo-request | Värd | `F22 ping från adminzon` | Nej | Utkast |
| F10 | In | Serverzon 10.40.1.96/27 | elev-38 | tcp/5432 | Värd | `F10 appen till databasen` | Nej | Utkast |
| D3/F18 | Ut | elev-38 | 185.12.64.1, 185.12.64.2 | udp/53, tcp/53 | Värd (molnet släpper alltid) | `D3/F18 DNS` | Nej | Utkast |
| D4/F19 | Ut | elev-38 | 213.239.239.164–.166 (ntp.hetzner.com) | udp/123 | Värd + moln | värd: `D4/F19 NTP`, moln: `F19 NTP ntp.hetzner.com (D4)` | Nej | Utkast |
| D5/F13 | Ut | elev-38 | log 172.20.1.58 | tcp/514 | Värd | `D5/F13 loggar till log (TCP 6514 med TLS från v5)` | Nej | Utkast |
| D6/F23 | Ut | elev-38 | DHCP-servrar | udp/68 → 67 | Värd (molnet släpper alltid) | `D6/F23 DHCP-förnyelse` | Nej | Utkast |
| D7/F20 | Ut | elev-38 | Internet | tcp/443 | Värd + moln | värd: `D7/F20 paketuppdateringar`, moln: `F20 paketuppdateringar dnf (D7)` | Nej | Utkast |
| Nekande | In och ut | Allt annat | – | – | Värd + moln | `policy drop` + `ZON-IN-DROP` / `ZON-UT-DROP` | Ja | Utkast |

F13 på TCP 6514 med TLS läggs till i vecka 5 och ersätter då D5. Fram till dess nekas tcp/6514 (testfall F13-nek-v4).

Ingen regel släpper DMZ → Databaszon. All åtkomst till data går via Serverzonen, och testfall F10-nek-dmz visar det.

Ingen generell öppning för ctf → tcp/80. Regeln (L1) fanns för U3.4, som är stängd, och står inte i flödestabellen. Öppningar för enskilda labbar läggs bara till när en labb kräver det, se [zoner-i-labbet](../../zoner-i-labbet.md).

Status ändras till **Verifierad** när raden har ett godkänt test i [testprotokollet](testprotokoll.md).
