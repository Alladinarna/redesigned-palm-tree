# Spårbarhetslista elev-46 (DMZ)

Varje regel i [zon.nft](zon.nft) och [molnregler.md](molnregler.md) kopplad till sin rad i flödestabellen och till testfallen i [testfall.csv](testfall.csv).

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager | Regelns identifierare | Testfall | Status |
|---|---|---|---|---|---|---|---|---|
| D1 (F16) | in | 172.20.1.2 (jump) | elev-46 | tcp/22 | värd | "D1 SSH från jump" | D1-till, D1-nek | verifierad |
| D2 | in | 172.20.1.10 (ctf) | elev-46 | tcp/22 | värd | "D2 kontroll från ctf" | – | aktiv |
| F4 | in | internet | elev-46 eth0 | tcp/80 | värd | "F4 internet till webb" | F4-till, F4-nek-eth1 | verifierad |
| F4 | in | 0.0.0.0/0 | elev-46 | tcp/80 | moln | molnregel 1 | F4-till, F4-nek | verifierad |
| D3 (F18) | ut | elev-46 | 185.12.64.1, 185.12.64.2 | tcp+udp/53 | värd | "D3 DNS" | D3-till, D3-nek | verifierad |
| D4 (F19) | ut | elev-46 | 213.239.239.164–166 | udp/123 | värd | "D4 tidssynk till Hetzner" | D4-till, D4-nek | verifierad |
| D4 (F19) | ut | elev-46 | 213.239.239.164–166 | udp/123 | moln | molnregel 2–4 | D4-till | verifierad |
| D5 | ut | elev-46 | 172.20.1.58 (log) | tcp/514 | värd | "D5 logg till log" | D5-till, D5-nek | verifierad |
| D6 (F23) | ut | elev-46 | DHCP-servern | udp 68 → 67 | värd | "D6 DHCP-förnyelse" | – | aktiv |
| D7 (F20) | ut | elev-46 | internet (eth0) | tcp/443 | värd | "D7 paketuppdateringar dnf" | D7-till, D7-nek | verifierad |
| D7 (F20) | ut | elev-46 | 0.0.0.0/0 | tcp/443 | moln | molnregel 5 | D7-till | verifierad |
| F9 | ut | elev-46 | 10.40.1.96/27 (serverzon) | tcp/8080 | värd | "F9 webben hämtar data från appservern" | F9-till, F9-nek | verifierad |
| N1 | in + ut | alla | alla | alla | värd + moln | policy drop + "ZON-IN-DROP" / "ZON-UT-DROP", moln nekar allt utan regel | alla nek-fall | verifierad |

Endast N1 loggar. Loggraderna skickas till loggservern via [60-brandvagg.conf](60-brandvagg.conf).

## Rader i flödestabellen som inte är implementerade på elev-46

| Rad-id | Varför | Testfall |
|---|---|---|
| F5 (443 in) | Webben har ingen TLS ännu. Öppnas när den har det | F5-nek |
| F11 (logg 6514 TLS) | TLS-insamlingen görs i vecka 5. Till dess skickas loggen klartext via D5 | F11-nek-v4 |
| F22 (ping från adminzon) | **Avvikelse.** Flödestabellen tillåter ping från adminzonen (jump) till DMZ, men zon.nft saknar regeln. Regelverket är snävare än tabellen och testfallet förväntade sig fel utfall. Rättas genom att lägga till regeln och ändra testfallet till F22-till | F22-nek |

## Status

- **verifierad:** testad med tillåtet och nekat fall, se resultatfilerna och [bevis-manuella.txt](bevis-manuella.txt). Fångst: elev-46-test.pcap.
- **aktiv:** regeln finns men har inget eget testfall. D2 bekräftas av att CTF-kontrollerna fungerar, och D6 av att servern behåller sina adresser.
