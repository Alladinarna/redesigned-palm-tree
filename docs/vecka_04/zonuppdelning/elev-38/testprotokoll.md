# Testprotokoll – elev-38 (Databaszon)

Varje rad i [spårbarhetslistan](sparbarhetslista.md) testas med ett tillåtet och ett nekat fall i [testfall.csv](testfall.csv). Testerna körs med [test.sh](test.sh) på den server som står som källa (elev-24, elev-38, elev-46, jump). En samtidig trafikfångst visar *vem* som nekade: ett utfall ensamt räcker inte, eftersom `tyst` också kan bero på fel adress eller att avsändarens egen utgående kedja kastade paketet.

## Förväntade paketmönster

| Utfall | Vad fångsten ska visa |
|---|---|
| oppen | SYN → SYN-ACK → ACK (eller DNS-/NTP-/ICMP-svar) |
| tyst | Upprepade SYN utan svar, och en `ZON-IN-DROP` eller `ZON-UT-DROP`-rad i `journalctl -k` på den server som står i kolumnen *nekas av* (eller ingen loggrad alls om det är molnbrandväggen) |
| avvisad | SYN → RST, eller ICMP destination unreachable |

Nekade fall in mot elev-38 körs från **jump** över labbnätet (172.20.1.138). Jumps egen trafik filtreras inte, så SYN-paketet når elev-38 och det är elev-38:s regel som stoppar det. Nekade fall som körs från en teamkamrat i teamnätet stoppas redan i teamkamratens utgående kedja, vilket också är rätt enligt flödestabellen, men syns då i *källserverns* logg.

## Förberedelser

- Lyssnare för rad 10 på elev-38: `ncat -lk 5432` (eller databasen om den finns).
- elev-24 kör 10-till, elev-46 kör 10-nek-dmz.
- Skriptet och testfallen kopieras till varje källa som behövs, även jump: `scp -r elev-38 jump:` och `scp -r elev-38 student@elev-38:` från repot.

## Körning

```
# terminal 1 på elev-38 – fångst på teamnätet och labbnätet, utan egen SSH
mkdir -p bevis
sudo tcpdump -nn -i any -w bevis/elev-38-test.pcap 'not port 22 or net 10.40.1.0/24'

# terminal 2 – på varje källa i tur och ordning
./test.sh testfall.csv

# efteråt på den server som ska ha nekat
journalctl -k -g ZON- --since "-15 min"
```

## Resultat

*Fylls i efter körning på workshop 2 (torsdag 29/10).*

| Id | Källa | Förväntat | Nekas av | Faktiskt | Paket i fångsten | Loggrad | Resultat |
|---|---|---|---|---|---|---|---|
| D1-till | jump | oppen | – | | | | |
| L1-nek | jump | tyst | elev-38 in | | | | |
| 22-till | jump | oppen | – | | | | |
| 10-till | elev-24 | oppen | – | | | | |
| 10-nek | jump | tyst | elev-38 in | | | | |
| 10-nek-dmz | elev-46 | tyst | elev-46 ut | | | | |
| ut-nek-intern | elev-38 | tyst | elev-38 ut | | | | |
| 13-till | elev-38 | oppen | – | | | | |
| D3-till | elev-38 | oppen | – | | | | |
| D3-nek | elev-38 | tyst | elev-38 ut | | | | |
| D4-till | elev-38 | oppen | – | | | | |
| D5-till | elev-38 | oppen | – | | | | |
| D5-nek | elev-38 | tyst | elev-38 ut | | | | |
| D7-till | elev-38 | oppen | – | | | | |
| D7-nek | elev-38 | tyst | elev-38 ut | | | | |

Avvikelser felsöks och testet körs om tills tabellen är stabil. Varje körning sparas som en egen `testprotokoll-elev-38-fran-<källa>-<tid>.csv` i `bevis/`.
