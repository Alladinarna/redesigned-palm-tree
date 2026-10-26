# Testprotokoll – elev-24 (Serverzon)

Varje rad i [spårbarhetslistan](sparbarhetslista.md) testas med ett tillåtet och ett nekat fall i [testfall.csv](testfall.csv). Testerna körs med [test.sh](test.sh) på den server som står som källa. En samtidig trafikfångst visar *vem* som nekade: ett utfall ensamt räcker inte, eftersom `tyst` också kan bero på fel adress eller att avsändarens egen utgående kedja kastade paketet.

## Förväntade paketmönster

| Utfall | Vad fångsten ska visa |
|---|---|
| oppen | SYN → SYN-ACK → ACK (eller DNS-/NTP-/ICMP-svar) |
| tyst | Upprepade SYN utan svar, och en `ZON-IN-DROP` eller `ZON-UT-DROP`-rad i `journalctl -k` på den server som nekade |
| avvisad | SYN → RST, eller ICMP destination unreachable |

För nekade fall in mot elev-24 ska SYN-paketet **synas på elev-24:s eth2** (det kom fram) och följas av en `ZON-IN-DROP`-rad. Då är det elev-24:s regel som stoppade, inte avsändarens.

## Förberedelser

- Lyssnare för testet på elev-24 (rad 8 och 9): `sudo ncat -lk 443` och `ncat -lk 8080` i varsin terminal.
- elev-38 lyssnar på tcp/5432 för rad 10, och har sin egen regel för rad 10 inkommande.
- elev-09 och elev-46 kör sina rader i `testfall.csv` med samma skript.

## Körning

```
# terminal 1 på elev-24 – fångst på teamnätet och labbnätet, utan egen SSH
mkdir -p bevis
sudo tcpdump -nn -i any -w bevis/elev-24-test.pcap 'not port 22 or net 10.40.1.0/24'

# terminal 2 på elev-24
./test.sh testfall.csv

# efteråt: vilka paket nekades och av vilken regel
journalctl -k -g ZON- --since "-15 min"
```

## Nollmätning före regelverket

Skriptet kördes på elev-24 2026-10-26T07:45Z, innan regelverket laddats och innan teamnätet fanns: [bevis/testprotokoll-elev-24-fore-regelverk.csv](bevis/testprotokoll-elev-24-fore-regelverk.csv).

- De nekade fallen **D3-nek, D7-nek** gav `oppen` och **D5-nek** gav `avvisad` (loggservern svarar RST på tcp/9000). Utan regelverk släpps alltså trafiken ut. När samma fall ger `tyst` efter att regelverket laddats är det regelverket som stoppar dem, inte en fel adress eller en tjänst som saknas.
- **10-till** gav `tyst` eftersom elev-38 ännu inte är kopplad till teamnätet. Det är ett exempel på ett nekat utfall som inte bevisar något om reglerna.
- Tillåtna driftflöden (D3, D4, D5, D7) gav `oppen`, så testfallen fungerar.

## Resultat

*Fylls i efter körning på workshop 2 (torsdag 29/10).*

| Id | Förväntat | Faktiskt | Paket i fångsten | Loggrad | Resultat |
|---|---|---|---|---|---|
| D1-till | oppen | | | | |
| D1-nek | tyst | | | | |
| 22-till | oppen | | | | |
| 22-nek | tyst | | | | |
| 8-till | oppen | | | | |
| 8-nek | tyst | | | | |
| 9-till | oppen | | | | |
| 9-nek | tyst | | | | |
| 10-till | oppen | | | | |
| 10-nek | tyst | | | | |
| D3-till | oppen | | | | |
| D3-till-tcp | oppen | | | | |
| D3-nek | tyst | | | | |
| D4-till | oppen | | | | |
| D5-till | oppen | | | | |
| D5-nek | tyst | | | | |
| D7-till | oppen | | | | |
| D7-nek | tyst | | | | |

Avvikelser felsöks och testet körs om tills tabellen är stabil. Varje omkörning sparas som en egen `testprotokoll-elev-24-<tid>.csv`.
