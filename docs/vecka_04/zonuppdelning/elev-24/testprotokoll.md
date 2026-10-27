# Testprotokoll – elev-24 (Serverzon)

Varje rad i [spårbarhetslistan](sparbarhetslista.md) testas med ett tillåtet och ett nekat fall i [testfall.csv](testfall.csv). Testerna körs med [test.sh](test.sh) på den server som står som källa (elev-09, elev-24, elev-46, jump). En samtidig trafikfångst visar *vem* som nekade: ett utfall ensamt räcker inte, eftersom `tyst` också kan bero på fel adress eller att avsändarens egen utgående kedja kastade paketet.

## Förväntade paketmönster

| Utfall | Vad fångsten ska visa |
|---|---|
| oppen | SYN → SYN-ACK → ACK (eller DNS-/NTP-/ICMP-svar) |
| tyst | Upprepade SYN utan svar, och en `ZON-IN-DROP` eller `ZON-UT-DROP`-rad i `journalctl -k` på den server som står i kolumnen *nekas av* (eller ingen loggrad alls om det är molnbrandväggen) |
| avvisad | SYN → RST, eller ICMP destination unreachable |

Nekade fall in mot elev-24 körs från **jump** över labbnätet (172.20.1.124). Jumps egen trafik filtreras inte, så SYN-paketet når elev-24 och det är elev-24:s regel som stoppar det. Nekade fall som körs från en teamkamrat i teamnätet stoppas redan i teamkamratens utgående kedja, vilket också är rätt enligt flödestabellen, men syns då i *källserverns* logg.

## Förberedelser

- Lyssnare för F8 och F9 på elev-24: `sudo ncat -lk 443` och `ncat -lk 8080` i varsin terminal.
- elev-38 lyssnar på tcp/5432 för F10, med sin egen inkommande regel för F10.
- Skriptet och testfallen kopieras till varje källa som behövs, även jump: `scp -r elev-24 jump:` och `scp -r elev-24 student@elev-24:` från repot.

## Körning

```
# terminal 1 på elev-24 – fångst på teamnätet och labbnätet, utan egen SSH
mkdir -p bevis
sudo tcpdump -nn -i any -w bevis/elev-24-test.pcap 'not port 22 or net 10.40.1.0/24'

# terminal 2 – på varje källa i tur och ordning
./test.sh testfall.csv

# efteråt på den server som ska ha nekat
journalctl -k -g ZON- --since "-15 min"
```

## Nollmätning före regelverket

Skriptet kördes på elev-24 2026-10-26T07:45Z, innan regelverket laddats och innan teamnätet fanns: [bevis/testprotokoll-elev-24-fore-regelverk.csv](bevis/testprotokoll-elev-24-fore-regelverk.csv). Den kördes med de adresser som gällde före Hugos adressplan (elev-38 = 10.40.1.210 i stället för 10.40.1.162), vilket inte påverkar resultatet eftersom teamnätet inte fanns än.

- De nekade fallen **D3-nek, D7-nek** gav `oppen` och **D5-nek** gav `avvisad` (loggservern svarar RST på tcp/9000). Utan regelverk släpps alltså trafiken ut. När samma fall ger `tyst` efter att regelverket laddats är det regelverket som stoppar dem, inte en fel adress eller en tjänst som saknas.
- **10-till** gav `tyst` eftersom elev-38 ännu inte är kopplad till teamnätet. Det är ett exempel på ett nekat utfall som inte bevisar något om reglerna.
- Tillåtna driftflöden (D3, D4, D5, D7) gav `oppen`, så testfallen fungerar.

## Resultat

*Fylls i efter körning på workshop 2 (torsdag 29/10).*

| Id | Källa | Förväntat | Nekas av | Faktiskt | Paket i fångsten | Loggrad | Resultat |
|---|---|---|---|---|---|---|---|
| D1-till | jump | oppen | – | | | | |
| L1-nek | jump | tyst | elev-24 in | | | | |
| 22-till | jump | oppen | – | | | | |
| 22-nek | elev-46 | tyst | elev-46 ut | | | | |
| 8-till | elev-09 | oppen | – | | | | |
| 8-nek | jump | tyst | elev-24 in | | | | |
| 9-till | elev-46 | oppen | – | | | | |
| 9-nek | jump | tyst | elev-24 in | | | | |
| 9-nek-intern | elev-46 | tyst | elev-46 ut | | | | |
| 10-till | elev-24 | oppen | – | | | | |
| 10-nek | elev-24 | tyst | elev-24 ut | | | | |
| 12-till | elev-24 | oppen | – | | | | |
| D3-till | elev-24 | oppen | – | | | | |
| D3-till-tcp | elev-24 | oppen | – | | | | |
| D3-nek | elev-24 | tyst | elev-24 ut | | | | |
| D4-till | elev-24 | oppen | – | | | | |
| D5-till | elev-24 | oppen | – | | | | |
| D5-nek | elev-24 | tyst | elev-24 ut | | | | |
| D7-till | elev-24 | oppen | – | | | | |
| D7-nek | elev-24 | tyst | elev-24 ut | | | | |

Avvikelser felsöks och testet körs om tills tabellen är stabil. Varje körning sparas som en egen `testprotokoll-elev-24-fran-<källa>-<tid>.csv` i `bevis/`.
