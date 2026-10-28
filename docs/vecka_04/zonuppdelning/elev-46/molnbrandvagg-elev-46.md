# Molnbrandväggen för elev-46

Molnbrandväggen filtrerar bara det publika gränssnittet (eth0). Trafik i labbnätet 172.20.1.0/24 och teamnätet 10.40.1.0/24 passerar inte den och filtreras på värden, se [elev-46-zon.nft](elev-46-zon.nft). elev-46 är den enda av teamets servrar som ska nås från internet.

## Inkommande

Den publika webben (F4–F5) ska nås från internet på tcp/80 och tcp/443, och inget annat. Inga breda portintervall. Kursens regel som stänger SSH från internet ligger kvar och kan inte tas bort.

## Utgående

Så fort den första utgående regeln finns nekas all annan utgående trafik mot internet. Därför måste NTP och paketuppdateringar stå med. Svaren till webbesökarna släpps ändå, eftersom molnbrandväggen är stateful. Namnuppslag mot Hetzners resolvrar (D3) och DHCP (D6) släpps alltid, men måste släppas på värden.

Körs på jump-servern av elev-46:

```
moln brandvägg regel lägg-till in tcp 80 0.0.0.0/0 "F4 webb http från internet"
moln brandvägg regel lägg-till in tcp 443 0.0.0.0/0 "F5 webb https från internet"
moln brandvägg regel lägg-till ut udp 123 213.239.239.164/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut udp 123 213.239.239.165/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut udp 123 213.239.239.166/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut tcp 443 0.0.0.0/0 "F20 paketuppdateringar dnf (D7)"
moln brandvägg regel lista
```

| Regel | Riktning | Protokoll/port | Källa/mål | Rad i flödestabellen |
|---|---|---|---|---|
| F4 webb http från internet | In | tcp/80 | 0.0.0.0/0 | F4 |
| F5 webb https från internet | In | tcp/443 | 0.0.0.0/0 | F5 |
| F19 NTP ntp.hetzner.com (D4) | Ut | udp/123 | 213.239.239.164, .165, .166 (tre regler, /32) | F19, D4 |
| F20 paketuppdateringar dnf (D7) | Ut | tcp/443 | 0.0.0.0/0 | F20, D7 |

Beskrivningen börjar med radens id i flödestabellen (krav i U4.4). NTP är låst till Hetzners NTP-servrar (ntp.hetzner.com), samma adresser som i värdens regelverk. Slutar tidssynken fungera kontrolleras adresserna med `getent ahostsv4 ntp.hetzner.com`.

Har en äldre regel med bredare mål eller utan F-id lagts in tidigare: lägg först till de nya reglerna, ta sedan bort den gamla med `moln brandvägg regel ta-bort NR` (numret från `moln brandvägg regel lista`).

## Kontroll

```
moln status
moln brandvägg regel lista
```

Från jump (som går ut på internet via eth0): `curl -sI http://46.224.175.57/` ska svara, medan tcp/8080 mot samma adress ska ge timeout (testfall F4-nek, stoppas i molnet).
