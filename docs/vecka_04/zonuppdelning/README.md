# Zonuppdelning – milstolpe 4: regelverk implementerat och verifierat

Utkast för teamets fyra servrar. Gemensamt underlag ligger här, och varje server har en egen mapp.

| Fil / mapp | Innehåll |
|---|---|
| [flodestabell-driftfloden.md](flodestabell-driftfloden.md) | Driftflöden D1–D7, zonernas adresser, rader per server och föreslagna ändringar i flödestabellen |
| [elev-09/](elev-09/) | Klientzon (10.40.1.10) |
| [elev-24/](elev-24/) | Serverzon (10.40.1.130) |
| [elev-38/](elev-38/) | Databaszon (10.40.1.210) |
| [elev-46/](elev-46/) | DMZ (10.40.1.226) |

Varje servermapp innehåller:

| Fil | Innehåll |
|---|---|
| `<server>-zon.nft` | Värdens regelverk i nftables, default deny i båda riktningarna |
| `60-brandvagg.conf` | rsyslog: brandväggsloggen till loggservern (D5) |
| `molnbrandvagg-<server>.md` | Molnbrandväggens regler (moln) |
| `sparbarhetslista.md` | Rad i flödestabellen → regel → lager → loggning → status |
| `testfall.csv` | Ett tillåtet och ett nekat testfall per rad, med var nekningen ska synas |
| `test.sh` | Kör de testfall vars källa är den egna servern och fyller i faktiskt utfall |
| `testprotokoll.md` | Paketmönster, förberedelser, körning och resultat |

## Ordning (varje medlem på sin egen server, byt elev-NN och adressen)

1. Teamnätet finns och servern är kopplad: `moln koppla 10.40.1.NN` på jump, kontrollera med `ip -br addr` att eth2 har rätt adress.
2. Två SSH-sessioner öppna mot servern.
3. Lägg regelverket på plats och ladda det med säkerhetsnät:

```
sudo cp elev-NN-zon.nft /etc/nftables/zon.nft
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

5. Molnbrandväggen enligt `molnbrandvagg-elev-NN.md`.
6. Testa enligt `testprotokoll.md` och uppdatera status i spårbarhetslistan. Samma skript kör alla servrars testfall från en källa: `for f in ../elev-*/testfall.csv; do ./test.sh "$f"; done`.

Har det gått fel: `moln återställ-ssh` på jump tar bort regelverket.

Syntaxen i alla fyra regelverk är kontrollerad med `nft -c` i ett eget nätverksnamnrymd på elev-24 (påverkar inte servern).
