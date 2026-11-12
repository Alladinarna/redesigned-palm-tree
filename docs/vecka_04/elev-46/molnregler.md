# Molnregler - elev-46 (DMZ)

| Regel | Id | Testfall |
|---|---|---|
| 1 in tcp 80 | F4 | F4-till, F4-nek |
| 2–4 ut udp 123 till Hetzners NTP | D4 (F19) | D4-till |
| 5 ut tcp 443 | D7 (F20) | D7-till |

F5 (443 in) är inte öppnad, eftersom webben saknar TLS. testas av F5- nek.
DNS (D3) och DHCP (D6) släpps alltid av getzner och filtreras bara i zon.nft.

Utskrift från "Moln brandvägg regel lista" på jump servern, 2026-11-0:

```

1  in  tcp  80   0.0.0.0/0           F4 trafik från internet ska nå webbservern
2  out udp  123  213.239.239.164/32  D4 min server måste nå denna för tidssynk
3  out udp  123  213.239.239.165/32  D4 min server måste nå denna för tidssynk
4  out udp  123  213.239.239.166/32  D4 min server måste nå denna för tidssynk
5  out tcp  443  0.0.0.0/0           D7 min server måste nå dnf servern för paketuppdateringar
```
