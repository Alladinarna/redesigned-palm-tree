# Molnbrandväggen för elev-24 (utkast)

Molnbrandväggen filtrerar bara det publika gränssnittet (eth0). Trafik i labbnätet 172.20.1.0/24 och teamnätet 10.40.1.0/24 passerar inte den och filtreras på värden, se [elev-24-zon.nft](elev-24-zon.nft).

## Inkommande

Inga regler. Serverzonen ska inte nås från internet (rad 4–5 gäller bara DMZ). Utan inkommande regler blockerar Hetzner all inkommande trafik. Kursens regel som stänger SSH från internet ligger kvar och kan inte tas bort.

## Utgående

Så fort den första utgående regeln finns nekas all annan utgående trafik mot internet. Därför måste NTP och paketuppdateringar stå med. Namnuppslag mot Hetzners resolvrar (D3) och DHCP (D6) släpps alltid av molnbrandväggen och behöver inga regler här, men måste släppas på värden.

Körs på jump-servern:

```
moln brandvägg regel lägg-till ut udp 123 0.0.0.0/0 "D4/19 NTP"
moln brandvägg regel lägg-till ut tcp 443 0.0.0.0/0 "D7/20 paketuppdateringar (dnf)"
moln brandvägg regel lista
```

| Regel | Riktning | Protokoll/port | Mål | Rad i flödestabellen |
|---|---|---|---|---|
| D4/19 NTP | Ut | udp/123 | 0.0.0.0/0 | D4, 19 |
| D7/20 paketuppdateringar (dnf) | Ut | tcp/443 | 0.0.0.0/0 | D7, 20 |

NTP-servern är ntp.hetzner.com (213.239.239.165 enligt `chronyc -n sources` på elev-24, 2026-10-26). Målet kan smalnas av till den adressen, men då slutar tiden fungera om Hetzner byter adress.

## Kontroll

```
moln status
moln brandvägg regel lista
```

Efteråt ska `curl -sI http://log.sec.chas-lab.dev/` från elev-24 ge timeout (tcp/80 ut står inte i tabellen), medan `dnf check-update` och `chronyc sources` fortsätter fungera.
