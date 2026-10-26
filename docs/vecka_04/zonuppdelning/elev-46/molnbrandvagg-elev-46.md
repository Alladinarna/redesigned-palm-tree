# Molnbrandväggen för elev-46 (utkast)

Molnbrandväggen filtrerar bara det publika gränssnittet (eth0). Trafik i labbnätet 172.20.1.0/24 och teamnätet 10.40.1.0/24 passerar inte den och filtreras på värden, se [elev-46-zon.nft](elev-46-zon.nft). elev-46 är den enda av teamets servrar som ska nås från internet.

## Inkommande

Den publika webben (rad 4–5) ska nås från internet på tcp/80 och tcp/443, och inget annat. Inga breda portintervall. Kursens regel som stänger SSH från internet ligger kvar och kan inte tas bort.

## Utgående

Så fort den första utgående regeln finns nekas all annan utgående trafik mot internet. Därför måste NTP och paketuppdateringar stå med. Svaren till webbesökarna släpps ändå, eftersom molnbrandväggen är stateful. Namnuppslag mot Hetzners resolvrar (D3) och DHCP (D6) släpps alltid, men måste släppas på värden.

Körs på jump-servern av elev-46:

```
moln brandvägg regel lägg-till in tcp 80 0.0.0.0/0 "4 webb (http) från internet"
moln brandvägg regel lägg-till in tcp 443 0.0.0.0/0 "5 webb (https) från internet"
moln brandvägg regel lägg-till ut udp 123 0.0.0.0/0 "D4/19 NTP"
moln brandvägg regel lägg-till ut tcp 443 0.0.0.0/0 "D7/20 paketuppdateringar (dnf)"
moln brandvägg regel lista
```

| Regel | Riktning | Protokoll/port | Källa/mål | Rad i flödestabellen |
|---|---|---|---|---|
| 4 webb (http) från internet | In | tcp/80 | 0.0.0.0/0 | 4 |
| 5 webb (https) från internet | In | tcp/443 | 0.0.0.0/0 | 5 |
| D4/19 NTP | Ut | udp/123 | 0.0.0.0/0 | D4, 19 |
| D7/20 paketuppdateringar (dnf) | Ut | tcp/443 | 0.0.0.0/0 | D7, 20 |

## Kontroll

```
moln status
moln brandvägg regel lista
```

Från jump (som går ut på internet via eth0): `curl -sI http://46.224.175.57/` ska svara, medan tcp/8080 mot samma adress ska ge timeout (testfall 4-nek, stoppas i molnet).
