# Testprotokoll – elev-09 (Klientzon)

Varje rad i [spårbarhetslistan](sparbarhetslista.md) testas med ett tillåtet och ett nekat fall i [testfall.csv](testfall.csv). Testerna körs med [test.sh](test.sh) på den server som står som källa (elev-09, elev-24, jump). En samtidig trafikfångst visar *vem* som nekade: ett utfall ensamt räcker inte, eftersom `tyst` också kan bero på fel adress eller att avsändarens egen utgående kedja kastade paketet.

## Förväntade paketmönster

| Utfall | Vad fångsten ska visa |
|---|---|
| oppen | SYN → SYN-ACK → ACK (eller DNS-/NTP-/ICMP-svar) |
| tyst | Upprepade SYN utan svar, och en `ZON-IN-DROP` eller `ZON-UT-DROP`-rad i `journalctl -k` på den server som står i kolumnen *nekas av* (eller ingen loggrad alls om det är molnbrandväggen) |
| avvisad | SYN → RST, eller ICMP destination unreachable |

Nekade fall in mot elev-09 körs från **jump** över labbnätet (172.20.1.109). Jumps egen trafik filtreras inte, så SYN-paketet når elev-09 och det är elev-09:s regel som stoppar det. Nekade fall som körs från en teamkamrat i teamnätet stoppas redan i teamkamratens utgående kedja, vilket också är rätt enligt flödestabellen, men syns då i *källserverns* logg.

## Förberedelser

- elev-09 behöver inga egna lyssnare (inga affärsflöden in).
- elev-24 lyssnar på tcp/443 för rad 8 (`sudo ncat -lk 443`).
- Skriptet och testfallen kopieras till varje källa som behövs, även jump: `scp -r elev-09 jump:` och `scp -r elev-09 student@elev-09:` från repot.

## Körning

```
# terminal 1 på elev-09 – fångst på teamnätet och labbnätet, utan egen SSH
mkdir -p bevis
sudo tcpdump -nn -i any -w bevis/elev-09-test.pcap 'not port 22 or net 10.40.1.0/24'

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
| L1-nek | jump | tyst | elev-09 in | | | | |
| 22-till | jump | oppen | – | | | | |
| in-nek-intern | elev-24 | tyst | elev-24 ut | | | | |
| 8-till | elev-09 | oppen | – | | | | |
| 8-nek | elev-09 | tyst | elev-09 ut | | | | |
| 8-nek-db | elev-09 | tyst | elev-09 ut | | | | |
| 6-till-80 | elev-09 | oppen | – | | | | |
| 6-till-443 | elev-09 | oppen | – | | | | |
| 6-nek | elev-09 | tyst | elev-09 ut | | | | |
| D3-till | elev-09 | oppen | – | | | | |
| D3-nek | elev-09 | tyst | elev-09 ut | | | | |
| D4-till | elev-09 | oppen | – | | | | |
| D5-till | elev-09 | oppen | – | | | | |
| D5-nek | elev-09 | tyst | elev-09 ut | | | | |

Avvikelser felsöks och testet körs om tills tabellen är stabil. Varje körning sparas som en egen `testprotokoll-elev-09-fran-<källa>-<tid>.csv` i `bevis/`.
