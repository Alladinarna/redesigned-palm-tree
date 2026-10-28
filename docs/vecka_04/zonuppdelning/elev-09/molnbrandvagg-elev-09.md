# Molnbrandväggen för elev-09

Molnbrandväggen filtrerar bara det publika gränssnittet (eth0). Trafik i labbnätet 172.20.1.0/24 och teamnätet 10.40.1.0/24 passerar inte den och filtreras på värden, se [elev-09-zon.nft](elev-09-zon.nft).

## Inkommande

Inga regler. Klientzonen ska inte nås från internet. Utan inkommande regler blockerar Hetzner all inkommande trafik. Kursens regel som stänger SSH från internet ligger kvar och kan inte tas bort.

## Utgående

Så fort den första utgående regeln finns nekas all annan utgående trafik mot internet. Klienterna surfar på webben (F6), så både tcp/80 och tcp/443 måste stå med, plus NTP. Paketuppdateringar (D7) går på tcp/443 och täcks av F6. Namnuppslag mot Hetzners resolvrar (D3) och DHCP (D6) släpps alltid av molnbrandväggen, men måste släppas på värden.

Körs på jump-servern av elev-09:

```
moln brandvägg regel lägg-till ut udp 123 213.239.239.164/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut udp 123 213.239.239.165/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut udp 123 213.239.239.166/32 "F19 NTP ntp.hetzner.com (D4)"
moln brandvägg regel lägg-till ut tcp 80 0.0.0.0/0 "F6 webb http"
moln brandvägg regel lägg-till ut tcp 443 0.0.0.0/0 "F6 webb https och paketuppdateringar (D7)"
moln brandvägg regel lista
```

| Regel | Riktning | Protokoll/port | Mål | Rad i flödestabellen |
|---|---|---|---|---|
| F19 NTP ntp.hetzner.com (D4) | Ut | udp/123 | 213.239.239.164, .165, .166 (tre regler, /32) | F19, D4 |
| F6 webb http | Ut | tcp/80 | 0.0.0.0/0 | F6 |
| F6 webb https och paketuppdateringar (D7) | Ut | tcp/443 | 0.0.0.0/0 | F6, D7 |

Beskrivningen börjar med radens id i flödestabellen (krav i U4.4). NTP är låst till Hetzners NTP-servrar (ntp.hetzner.com), samma adresser som i värdens regelverk. Slutar tidssynken fungera kontrolleras adresserna med `getent ahostsv4 ntp.hetzner.com`.

Har en äldre regel med bredare mål eller utan F-id lagts in tidigare: lägg först till de nya reglerna, ta sedan bort den gamla med `moln brandvägg regel ta-bort NR` (numret från `moln brandvägg regel lista`).

## Kontroll

```
moln status
moln brandvägg regel lista
```

Efteråt ska `curl -sI https://download.rockylinux.org/` fungera från elev-09, men inte TCP mot 8.8.8.8 port 53 (testfall F6-nek).
