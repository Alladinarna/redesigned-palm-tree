# Flödestabell vecka 4: driftflöden och labbadresser (utkast)

Tillägg till [flödestabellen från vecka 3](../../vecka_03/flodestabell.md). Med default deny i båda riktningarna stängs allt som servern själv behöver om det inte står i tabellen. Här läggs driftflödena D1–D7 till, och varje zon får de adresser som reglerna skrivs med.

## Zonernas adresser i labbet

Ur [adressplanen](../../vecka_02/adressplan.md) (teamnät 10.40.1.0/24) och [zoner-i-labbet](../zoner-i-labbet.md). Jump och loggservern ligger kvar i kursens labbnät, så reglerna använder deras verkliga adresser.

| Zon | Adress i reglerna | Labbserver |
|---|---|---|
| Klientzon | 10.40.1.0/26 | elev-09 (10.40.1.2) |
| Serverzon | 10.40.1.96/27 | elev-24 (10.40.1.98) |
| Databaszon | 10.40.1.160/29 | elev-38 (10.40.1.162) |
| DMZ | 10.40.1.144/29 | elev-46 (10.40.1.146) |
| Adminzon | 172.20.1.2 | jump |
| Loggzon | 172.20.1.58 | log |
| Kursens kontrolltjänst | 172.20.1.10 | ctf |

## Driftflöden

Gäller alla fyra servrar. Id:t används som kommentar i nftables och som början på beskrivningen i molnbrandväggen.

| Rad | Källa | Mål | Protokoll | Port | Riktning | Motivering | Filtreras var | Motsvarar rad i v3 |
|---|---|---|---|---|---|---|---|---|
| D1 | jump 172.20.1.2 | Egen server | TCP | 22 | Inkommande | Administration via jump | Värd (nftables), labbnätet passerar inte molnbrandväggen | 16 |
| D2 | ctf 172.20.1.10 | Egen server | TCP | 22 | Inkommande | Kursens kontrolltjänst loggar in på servern | Värd (nftables) | 24 |
| D3 | Egen server | Hetzners resolvrar 185.12.64.1, 185.12.64.2 | UDP och TCP | 53 | Utgående | Namnuppslag. TCP behövs för stora svar | Värd (nftables). Molnbrandväggen släpper alltid Hetzners DNS | 7, 18 |
| D4 | Egen server | Internet (ntp.hetzner.com) | UDP | 123 | Utgående | Korrekt tid för loggar, inloggningar och certifikat (chrony) | Värd (nftables) och molnbrandvägg | 19 |
| D5 | Egen server | log 172.20.1.58 | TCP | 514 | Utgående | Brandväggsloggen skickas till loggservern. Klartext i v4, byts mot TLS på 6514 i v5 | Värd (nftables) | 25 (rad 11–14 gäller från v5) |
| D6 | Egen server | DHCP-servrarna 172.31.1.1 (eth0), 172.20.0.1 (eth1), 10.40.1.1 (eth2) | UDP | 68 → 67 | Utgående | Förnyelse av serverns adresser. Utan regeln tappar servern adressen när lånet (24 h) går ut | Värd (nftables). Molnbrandväggen släpper alltid DHCP | 23 |
| D7 | Egen server | Internet (paketförråd) | TCP | 443 | Utgående | Säkerhetsuppdateringar via dnf | Värd (nftables) och molnbrandvägg | 20 |

Svarstrafik på tillåtna flöden släpps av `ct state established,related` och behöver inga egna rader.

## Ändringar i flödestabellen (v3)

Genomförda i [flödestabellen](../../vecka_03/flodestabell.md) 2026-10-26:

1. **Rad 7 och 18** – "extern DNS" är Hetzners resolvrar (185.12.64.1, 185.12.64.2) på både UDP och TCP 53, och filtreras på värden.
2. **Rad 23** – DHCP gäller alla tre gränssnitt.
3. **Rad 24 (ny)** – ctf-servern behöver SSH och tcp/80 (D2, L1).
4. **Rad 25 (ny)** – loggarna går på TCP 514 i vecka 4. Rad 11–14 (TCP 6514 med TLS) gäller från vecka 5.

Kvar att göra: zonernas adresser står i [adressplanen](../../vecka_02/adressplan.md) och [zoner-i-labbet](../zoner-i-labbet.md), men inte i själva flödestabellen.

## Rader per server

Alla fyra har D1–D7, rad 22 (ping från jump) och L1 (ctf → tcp/80, labbkrav enligt zoner-i-labbet). Utöver det:

| Server | Zon | In | Ut | Mapp |
|---|---|---|---|---|
| elev-09 | Klientzon | – | 6 (webb tcp/80, 443), 8 (→ Serverzon tcp/443) | [elev-09](elev-09/) |
| elev-24 | Serverzon | 8 (från Klientzon tcp/443), 9 (från DMZ tcp/8080) | 10 (→ Databaszon tcp/5432), 12 (→ log tcp/6514) | [elev-24](elev-24/) |
| elev-38 | Databaszon | 10 (från Serverzon tcp/5432) | 13 (→ log tcp/6514) | [elev-38](elev-38/) |
| elev-46 | DMZ | 4–5 (från internet tcp/80, 443) | 9 (→ Serverzon tcp/8080), 11 (→ log tcp/6514) | [elev-46](elev-46/) |

Varje mapp har regelverket (`<server>-zon.nft`), rsyslog-filen, molnbrandväggen, spårbarhetslistan, testfallen, testskriptet och testprotokollet.
