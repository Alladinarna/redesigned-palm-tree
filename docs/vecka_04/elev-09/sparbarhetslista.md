# Spårbarhetslista elev-09 (Klientzon)

| Rad-id | Riktning | Källa | Mål | Proto/port | Lager | Regelns identifierare | Loggar? | Status |
|---|---|---|---|---|---|---|---|---|
| D1 | in | 172.20.1.2 (jump) | elev-09 | tcp/22 | värd | "D1 SSH från jump" | nej | verifierad |
| D2 | in | 172.20.1.10 (ctf) | elev-09 | tcp/22 | värd | "D2 kontroll från ctf" | nej | verifierad |
| D3 | ut | elev-09 | 185.12.64.1, 185.12.64.2 | tcp+udp/53 | värd | "D3 DNS" | nej | aktiv |
| D4 | ut | elev-09 | 213.239.239.164–166 | udp/123 | värd | "D4 NTP" | nej | verifierad |
| D5 | ut | elev-09 | 172.20.1.58 (log) | tcp/514 | värd | "D5 logg till log" | nej | verifierad |
| D6 | ut | elev-09 | DHCP-servern (alla nät) | udp 68 → 67 | värd | "D6 DHCP" | nej | aktiv |
| F6 | ut | elev-09 | internet (via eth0) | tcp/80, 443 | värd | "F6 webb ut (även D7 dnf)" | nej | aktiv |
| F8 | ut | elev-09 | 10.40.1.98 (appserver) | tcp/443 | värd | "F8 klient till applikation" | nej | aktiv |
| F6 | ut | elev-09 | 0.0.0.0/0 | tcp/80, 443 | moln | moln regel 1–2 | nej | aktiv |
| D4 | ut | elev-09 | 213.239.239.164–166 | udp/123 | moln | moln regel 3–5 | nej | verifierad |
| N1 | in + ut | alla | alla | alla | värd + moln | policy drop + "ZON-IN-DROP" / "ZON-UT-DROP", moln implicit neka ut | ja (värd) | verifierad |