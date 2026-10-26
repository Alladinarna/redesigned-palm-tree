# Zonuppdelning – milstolpe 4: regelverk implementerat och verifierat

Utkast för elev-24 (Serverzon). Samma struktur kan kopieras för elev-09, elev-38 och elev-46.

| Fil | Innehåll |
|---|---|
| [flodestabell-driftfloden.md](flodestabell-driftfloden.md) | Driftflöden D1–D7, zonernas adresser och föreslagna ändringar i flödestabellen |
| [elev-24-zon.nft](elev-24-zon.nft) | Värdens regelverk i nftables, default deny i båda riktningarna |
| [60-brandvagg.conf](60-brandvagg.conf) | rsyslog: brandväggsloggen till loggservern (D5) |
| [molnbrandvagg-elev-24.md](molnbrandvagg-elev-24.md) | Molnbrandväggens regler (moln) |
| [sparbarhetslista.md](sparbarhetslista.md) | Rad i flödestabellen → regel → lager → loggning → status |
| [testfall.csv](testfall.csv) | Ett tillåtet och ett nekat testfall per rad |
| [test.sh](test.sh) | Kör testfallen och fyller i faktiskt utfall |
| [testprotokoll.md](testprotokoll.md) | Paketmönster, körning och resultat |

## Ordning

1. Teamnätet finns och elev-24 är kopplad: `moln koppla 10.40.1.130` på jump, kontrollera med `ip -br addr` att eth2 har 10.40.1.130.
2. Två SSH-sessioner öppna mot elev-24.
3. Lägg regelverket på plats och ladda det med säkerhetsnät:

```
sudo cp elev-24-zon.nft /etc/nftables/zon.nft
echo 'include "/etc/nftables/zon.nft"' | sudo tee -a /etc/sysconfig/nftables.conf
sudo nft -c -f /etc/nftables/zon.nft                                     # syntaxkontroll
sudo systemd-run --on-active=5min --unit=nodbroms nft flush ruleset     # säkerhetsnät
sudo nft -f /etc/nftables/zon.nft
# öppna en ny session via jump – fungerar den:
sudo systemctl stop nodbroms.timer
sudo systemctl enable --now nftables                                     # överlever omstart
```

4. Brandväggsloggen till loggservern:

```
sudo cp 60-brandvagg.conf /etc/rsyslog.d/60-brandvagg.conf
sudo systemctl restart rsyslog
journalctl -k -g ZON- --since "-10 min"
```

5. Molnbrandväggen enligt [molnbrandvagg-elev-24.md](molnbrandvagg-elev-24.md).
6. Testa enligt [testprotokoll.md](testprotokoll.md) och uppdatera status i spårbarhetslistan.

Har det gått fel: `moln återställ-ssh` på jump tar bort regelverket.

Syntaxen i elev-24-zon.nft är kontrollerad med `nft -c` i ett eget nätverksnamnrymd på elev-24 (påverkar inte servern), se commit-historiken.
