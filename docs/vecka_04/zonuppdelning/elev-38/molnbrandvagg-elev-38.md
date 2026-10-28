# Molnbrandväggen för elev-38

Molnbrandväggen filtrerar bara det publika gränssnittet (eth0). Trafik i labbnätet 172.20.1.0/24 och teamnätet 10.40.1.0/24 passerar inte den och filtreras på värden, se [elev-38-zon.nft](elev-38-zon.nft). Databasflödet från Serverzonen (F10) går i teamnätet och syns därför bara på värden.

## Inkommande

Inga regler. Databaszonen ska aldrig nås från internet. Utan inkommande regler blockerar Hetzner all inkommande trafik. Kursens regel som stänger SSH från internet ligger kvar och kan inte tas bort.

## Utgående

Så fort den första utgående regeln finns nekas all annan utgående trafik mot internet. Därför måste NTP och paketuppdateringar stå med. Namnuppslag mot Hetzners resolvrar (D3) och DHCP (D6) släpps alltid av molnbrandväggen, men måste släppas på värden.

Körs på jump-servern av elev-38:

```
moln brandvägg regel lägg-till ut udp 123 213.239.239.164/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut udp 123 213.239.239.165/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut udp 123 213.239.239.166/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut tcp 443 0.0.0.0/0 "F20 paketuppdateringar dnf (D7)"
moln brandvägg regel lista
```

| Regel | Riktning | Protokoll/port | Mål | Rad i flödestabellen |
|---|---|---|---|---|
| F19 NTP ntp.hetzner.com (D4) | Ut | udp/123 | 213.239.239.164, .165, .166 (tre regler, /32) | F19, D4 |
| F20 paketuppdateringar dnf (D7) | Ut | tcp/443 | 0.0.0.0/0 | F20, D7 |

Beskrivningen börjar med radens id i flödestabellen (krav i U4.4). NTP är låst till Hetzners NTP-servrar (ntp.hetzner.com), samma adresser som i värdens regelverk. Slutar tidssynken fungera kontrolleras adresserna med `getent ahostsv4 ntp.hetzner.com`.

Har en äldre regel med bredare mål eller utan F-id lagts in tidigare: lägg först till de nya reglerna, ta sedan bort den gamla med `moln brandvägg regel ta-bort NR` (numret från `moln brandvägg regel lista`).

## Kontroll

```
moln status
moln brandvägg regel lista
```

Efteråt ska `curl -sI http://log.sec.chas-lab.dev/` från elev-38 ge timeout (tcp/80 ut står inte i tabellen), medan `dnf check-update` och `chronyc sources` fortsätter fungera.
