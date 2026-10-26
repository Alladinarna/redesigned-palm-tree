# Molnbrandväggen för elev-09 (utkast)

Molnbrandväggen filtrerar bara det publika gränssnittet (eth0). Trafik i labbnätet 172.20.1.0/24 och teamnätet 10.40.1.0/24 passerar inte den och filtreras på värden, se [elev-09-zon.nft](elev-09-zon.nft).

## Inkommande

Inga regler. Klientzonen ska inte nås från internet. Utan inkommande regler blockerar Hetzner all inkommande trafik. Kursens regel som stänger SSH från internet ligger kvar och kan inte tas bort.

## Utgående

Så fort den första utgående regeln finns nekas all annan utgående trafik mot internet. Klienterna surfar på webben (rad 6), så både tcp/80 och tcp/443 måste stå med, plus NTP. Namnuppslag mot Hetzners resolvrar (D3) och DHCP (D6) släpps alltid av molnbrandväggen, men måste släppas på värden.

Körs på jump-servern av elev-09:

```
moln brandvägg regel lägg-till ut udp 123 0.0.0.0/0 "D4/19 NTP"
moln brandvägg regel lägg-till ut tcp 80 0.0.0.0/0 "6 webb (http)"
moln brandvägg regel lägg-till ut tcp 443 0.0.0.0/0 "6/D7 webb (https) och paketuppdateringar"
moln brandvägg regel lista
```

| Regel | Riktning | Protokoll/port | Mål | Rad i flödestabellen |
|---|---|---|---|---|
| D4/19 NTP | Ut | udp/123 | 0.0.0.0/0 | D4, 19 |
| 6 webb (http) | Ut | tcp/80 | 0.0.0.0/0 | 6 |
| 6/D7 webb (https) och paketuppdateringar | Ut | tcp/443 | 0.0.0.0/0 | 6, D7 |

## Kontroll

```
moln status
moln brandvägg regel lista
```

Efteråt ska `curl -sI https://download.rockylinux.org/` fungera från elev-09, men inte TCP mot 8.8.8.8 port 53 (testfall 6-nek).
