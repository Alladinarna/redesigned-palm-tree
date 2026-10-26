# Flödestabell vecka 4: driftflöden och labbadresser (utkast)

Tillägg till [flödestabellen från vecka 3](../../vecka_03/flodestabell.md). Med default deny i båda riktningarna stängs allt som servern själv behöver om det inte står i tabellen. Här läggs driftflödena D1–D7 till, och varje zon får de adresser som reglerna skrivs med.

## Zonernas adresser i labbet

Ur [adressplanen](../../vecka_02/adressplan.md) (teamnät 10.40.1.0/24) och [zoner-i-labbet](../zoner-i-labbet.md). Jump och loggservern ligger kvar i kursens labbnät, så reglerna använder deras verkliga adresser.

| Zon | Adress i reglerna | Labbserver |
|---|---|---|
| Klientzon | 10.40.1.0/25 | elev-09 (10.40.1.10) |
| Serverzon | 10.40.1.128/27 | elev-24 (10.40.1.130) |
| Databaszon | 10.40.1.208/29 | elev-38 (10.40.1.210) |
| DMZ | 10.40.1.224/29 | elev-46 (10.40.1.226) |
| Adminzon | 172.20.1.2 | jump |
| Loggzon | 172.20.1.58 | log |
| Kursens kontrolltjänst | 172.20.1.10 | ctf |

## Driftflöden

Gäller alla fyra servrar. Id:t används som kommentar i nftables och som början på beskrivningen i molnbrandväggen.

| Rad | Källa | Mål | Protokoll | Port | Riktning | Motivering | Filtreras var | Motsvarar rad i v3 |
|---|---|---|---|---|---|---|---|---|
| D1 | jump 172.20.1.2 | Egen server | TCP | 22 | Inkommande | Administration via jump | Värd (nftables), labbnätet passerar inte molnbrandväggen | 16 |
| D2 | ctf 172.20.1.10 | Egen server | TCP | 22 | Inkommande | Kursens kontrolltjänst loggar in på servern | Värd (nftables) | Ny |
| D3 | Egen server | Hetzners resolvrar 185.12.64.1, 185.12.64.2 | UDP och TCP | 53 | Utgående | Namnuppslag. TCP behövs för stora svar | Värd (nftables). Molnbrandväggen släpper alltid Hetzners DNS | 18 (utökas med TCP) |
| D4 | Egen server | Internet (ntp.hetzner.com) | UDP | 123 | Utgående | Korrekt tid för loggar, inloggningar och certifikat (chrony) | Värd (nftables) och molnbrandvägg | 19 |
| D5 | Egen server | log 172.20.1.58 | TCP | 514 | Utgående | Brandväggsloggen skickas till loggservern. Klartext i v4, byts mot TLS på 6514 i v5 | Värd (nftables) | Ny (rad 11–13 gäller från v5) |
| D6 | Egen server | DHCP-servrarna 172.31.1.1 (eth0), 172.20.0.1 (eth1), 10.40.1.1 (eth2) | UDP | 68 → 67 | Utgående | Förnyelse av serverns adresser. Utan regeln tappar servern adressen när lånet (24 h) går ut | Värd (nftables). Molnbrandväggen släpper alltid DHCP | 23 (utökas med eth1 och eth2) |
| D7 | Egen server | Internet (paketförråd) | TCP | 443 | Utgående | Säkerhetsuppdateringar via dnf | Värd (nftables) och molnbrandvägg | 20 |

Svarstrafik på tillåtna flöden släpps av `ct state established,related` och behöver inga egna rader.

## Föreslagna ändringar i flödestabellen (v3)

1. **Rad 18** – lägg till TCP 53 och skriv resolvrarnas adresser (185.12.64.1, 185.12.64.2).
2. **Rad 23** – DHCP gäller alla tre gränssnitt, inte bara den externa gatewayen.
3. **Rad 11–14** – loggarna går på TCP 514 i vecka 4. TCP 6514 med TLS gäller från vecka 5.
4. **Ny rad D2** – ctf-servern behöver SSH, inte bara tcp/80 som står i zoner-i-labbet.
5. **Rad 8–10, 12** – lägg till adresserna ur tabellen ovan, så att någon annan kan implementera raderna utan att fråga.

## Rader som gäller elev-24 (Serverzon)

| Rad | Riktning | Flöde |
|---|---|---|
| D1/16 | In | jump → elev-24 tcp/22 |
| D2 | In | ctf → elev-24 tcp/22 |
| 8 | In | Klientzon → elev-24 tcp/443 |
| 9 | In | DMZ → elev-24 tcp/8080 |
| 22 | In | jump → elev-24 ICMP echo |
| L1 | In | ctf → elev-24 tcp/80 (labbkrav, se zoner-i-labbet) |
| 10 | Ut | elev-24 → Databaszon tcp/5432 |
| 12 | Ut | elev-24 → log tcp/6514 (från v5) |
| D3–D7 | Ut | Driftflöden enligt tabellen ovan |

Regelverket finns i [elev-24-zon.nft](elev-24-zon.nft) och spårbarheten i [sparbarhetslista.md](sparbarhetslista.md).
