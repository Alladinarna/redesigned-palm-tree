# Zonuppdelning – milstolpe 4: regelverk implementerat och verifierat

Utkast för teamets fyra servrar. Gemensamt underlag ligger här, och varje server har en egen mapp.

| Fil / mapp | Innehåll |
|---|---|
| [flodestabell-driftfloden.md](flodestabell-driftfloden.md) | Zonernas adresser och vilka rader i flödestabellen (F1–F24, D1–D7) som hamnar på vilken server |
| [ladda-zon.sh](ladda-zon.sh) | Laddar den egna serverns regelverk med säkerhetsnät (väljer fil efter värdnamnet) |
| [elev-09/](elev-09/) | Klientzon (10.40.1.2) |
| [elev-24/](elev-24/) | Serverzon (10.40.1.98) |
| [elev-38/](elev-38/) | Databaszon (10.40.1.162) |
| [elev-46/](elev-46/) | DMZ (10.40.1.146) |

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
3. Kopiera hela mappen `zonuppdelning` till servern och ladda regelverket med säkerhetsnät:

```
scp -r zonuppdelning lab:                     # från repot på din dator
cd ~/zonuppdelning
sudo bash ladda-zon.sh     # syntaxkontroll, backup, include (bara en gång), nödbroms 5 min, laddning
# öppna en NY session via jump. Fungerar den, stoppa nödbromsen direkt:
sudo systemctl stop nodbroms.timer
```

   Glöms timern töms regelverket efter 5 minuter. Ladda då om med `sudo nft -f /etc/nftables/zon.nft`. Skriptet aktiverar nftables-tjänsten, så regelverket laddas vid omstart. Kontrollera det med `sudo reboot` och sedan `sudo nft list ruleset | grep comment`.

4. Brandväggsloggen till loggservern:

```
sudo cp 60-brandvagg.conf /etc/rsyslog.d/60-brandvagg.conf
sudo systemctl restart rsyslog
journalctl -k -g ZON- --since "-10 min"
```

   Att raden har kommit fram till loggservern kontrolleras på jump med `loggsök ZON-`.

5. Molnbrandväggen enligt `molnbrandvagg-elev-NN.md`.
6. Testa enligt `testprotokoll.md` och uppdatera status i spårbarhetslistan. Samma skript kör alla servrars testfall från en källa: `for f in ../elev-*/testfall.csv; do bash test.sh "$f"; done`. Kör med `bash`, eftersom körrättigheten inte följer med scp från Windows.

Har det gått fel: `moln återställ-ssh` på jump tar bort regelverket.

Syntaxen i alla fyra regelverk är kontrollerad 2026-10-28 med `unshare -rn nft -c` på elev-24 (eget nätverksnamnrymd, påverkar inte servern).
