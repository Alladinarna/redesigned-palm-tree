# Molnbrandväggen för elev-38 (utkast)

Molnbrandväggen filtrerar bara det publika gränssnittet (eth0). Trafik i labbnätet 172.20.1.0/24 och teamnätet 10.40.1.0/24 passerar inte den och filtreras på värden, se [elev-38-zon.nft](elev-38-zon.nft). Databasflödet från Serverzonen (rad 10) går i teamnätet och syns därför bara på värden.

## Inkommande

Inga regler. Databaszonen ska aldrig nås från internet. Utan inkommande regler blockerar Hetzner all inkommande trafik. Kursens regel som stänger SSH från internet ligger kvar och kan inte tas bort.

## Utgående

Så fort den första utgående regeln finns nekas all annan utgående trafik mot internet. Därför måste NTP och paketuppdateringar stå med. Namnuppslag mot Hetzners resolvrar (D3) och DHCP (D6) släpps alltid av molnbrandväggen, men måste släppas på värden.

Körs på jump-servern av elev-38:

```
moln brandvägg regel lägg-till ut udp 123 0.0.0.0/0 "D4/19 NTP"
moln brandvägg regel lägg-till ut tcp 443 0.0.0.0/0 "D7/20 paketuppdateringar (dnf)"
moln brandvägg regel lista
```

| Regel | Riktning | Protokoll/port | Mål | Rad i flödestabellen |
|---|---|---|---|---|
| D4/19 NTP | Ut | udp/123 | 0.0.0.0/0 | D4, 19 |
| D7/20 paketuppdateringar (dnf) | Ut | tcp/443 | 0.0.0.0/0 | D7, 20 |

## Kontroll

```
moln status
moln brandvägg regel lista
```

Efteråt ska `curl -sI http://log.sec.chas-lab.dev/` från elev-38 ge timeout (tcp/80 ut står inte i tabellen), medan `dnf check-update` och `chronyc sources` fortsätter fungera.
