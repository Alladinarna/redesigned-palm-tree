# Spårbarhetslista – elev-24 (Serverzon)

Varje rad i flödestabellen som gäller elev-24, och var den är implementerad. Regelns identifierare är kommentaren i [elev-24-zon.nft](elev-24-zon.nft) eller beskrivningen i [molnbrandväggen](molnregler.md). Rad-id (F1–F24, D1–D7) enligt [flödestabellen](../../vecka_03/flodestabell.md).

**Loggar?** Tillåtande regler loggar inte. Allt som inte släpps av någon regel loggas av den sista regeln i kedjan (`ZON-IN-DROP` / `ZON-UT-DROP`) och skickas till loggservern (D5).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager (moln/värd) | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1/F16 | In | jump 172.20.1.2 | elev-24 | tcp/22 | Värd | `D1/F16 SSH från jump` | Nej | Verifierad 28/10 och 2/11 (D1-till från jump i två körningar 08:25Z och 08:26Z och efter omstarten 08:42Z) |
| D2 | In | ctf 172.20.1.10 | elev-24 | tcp/22 | Värd | `D2 kontroll från ctf` | Nej | Inget testfall, eftersom källan är ctf. Regeln finns i det laddade regelverket |
| F22 | In | jump 172.20.1.2 | elev-24 | icmp echo-request | Värd | `F22 ping från adminzon` | Nej | Verifierad 2/11 (F22-till från jump: 2 av 2 svar i båda körningarna och efter omstarten 08:42Z) |
| F8 | In | Klientzon 10.40.1.0/26 (elev-09) | elev-24 | tcp/443 | Värd | `F8 klienter till intern webbapp` | Nej | Nekfallet verifierat 2/11 (F8-nek: tcp/443 från jump tyst, `ZON-IN-DROP`). F8-till körs från elev-09 och är inte körd från elev-24 |
| F9 | In | DMZ 10.40.1.144/29 (elev-46) | elev-24 | tcp/8080 | Värd | `F9 DMZ hämtar data från appservern` | Nej | Nekfallet verifierat 2/11 (F9-nek: tcp/8080 från jump tyst, `ZON-IN-DROP`). F9-till körs från elev-46 och är inte körd från elev-24 |
| F10 | Ut | elev-24 | Databaszon 10.40.1.160/29 (elev-38) | tcp/5432 | Värd | `F10 appen till databasen` | Nej | Kedjan ut släpper (fångst 2/11: SYN ut på eth2, elev-38 svarar RST). F10-till AVVIKER (avvisad), och orsaken kontrolleras på elev-38. F10-nek OK |
| D3/F18 | Ut | elev-24 | 185.12.64.1, 185.12.64.2 | udp/53, tcp/53 | Värd (molnet släpper alltid) | `D3/F18 DNS` | Nej | Verifierad 28/10 och 2/11 (två körningar och efter omstart) |
| D4/F19 | Ut | elev-24 | 213.239.239.164–.166 (ntp.hetzner.com) | udp/123 | Värd + moln | värd: `D4/F19 NTP`, moln: `F19 NTP ntp.hetzner.com (D4)` | Nej | Verifierad 28/10 och 2/11 (två körningar och efter omstart). Molnregeln kontrollerades med `moln brandvägg regel lista` 2/11 |
| D5/F12 | Ut | elev-24 | log 172.20.1.58 (bara via eth1) | tcp/6514 (TLS) | Värd | `D5/F12 loggar till log över TLS via labbnätet (v5)` | Nej | Verifierad 2/11 08:07Z (D5-till 6514 oppen, D5-nek-klartext 514 tyst). `oifname "eth1"` tillagt 08:37Z och verifierat före och efter omstart 08:38Z. Loggrader över TLS på log, se [vecka 5](../../vecka_05/elev-24/verifieringsanteckning.md) |
| D6/F23 | Ut | elev-24 | DHCP-servrar | udp/68 → 67 | Värd (molnet släpper alltid) | `D6/F23 DHCP-förnyelse` | Nej | Inget testfall. Regeln finns i det laddade regelverket |
| D7/F20 | Ut | elev-24 | Internet | tcp/443 | Värd + moln | värd: `D7/F20 paketuppdateringar`, moln: `F20 paketuppdateringar dnf` | Nej | Verifierad 28/10 och 2/11 (två körningar och efter omstart). Molnregeln kontrollerades med `moln brandvägg regel lista` 2/11 |
| Nekande | In och ut | Allt annat | – | – | Värd + moln | `policy drop` + `ZON-IN-DROP` / `ZON-UT-DROP` | Ja | Kedjan ut verifierad 28/10 och 2/11. Kedjan in verifierad 2/11 (80-nek, F8-nek och F9-nek från jump var tysta, `ZON-IN-DROP IN=eth1`). Molnet har inga inkommande regler |

Från vecka 5 går D5/F12 på TCP 6514 med TLS och klartext på TCP 514 nekas (testfall D5-nek-klartext), se [vecka 5](../../vecka_05/elev-24/README.md). Öppningar för enskilda labbar (till exempel ctf → tcp/80) läggs bara till när labben kräver det, se [zoner-i-labbet](../zoner-i-labbet.md).

Rader i flödestabellen som inte gäller elev-24 (t.ex. F4–F5, F11, F13) implementeras på respektive teamkamrats server.

Status ändras till **Verifierad** när raden har ett godkänt test i [testprotokollet](testprotokoll.md).
