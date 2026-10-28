# Testprotokoll – elev-46 (DMZ)

Varje rad i [spårbarhetslistan](sparbarhetslista.md) testas med ett tillåtet och ett nekat fall i [testfall.csv](testfall.csv). Testerna körs med [test.sh](test.sh) på den server som står som källa (elev-46, jump). En samtidig trafikfångst visar *vem* som nekade: ett utfall ensamt räcker inte, eftersom `tyst` också kan bero på fel adress eller att avsändarens egen utgående kedja kastade paketet.

## Förväntade paketmönster

| Utfall | Vad fångsten ska visa |
|---|---|
| oppen | SYN → SYN-ACK → ACK (eller DNS-/NTP-/ICMP-svar) |
| tyst | Upprepade SYN utan svar, och en `ZON-IN-DROP` eller `ZON-UT-DROP`-rad i `journalctl -k` på den server som står i kolumnen *nekas av* (eller ingen loggrad alls om det är molnbrandväggen) |
| avvisad | SYN → RST, eller ICMP destination unreachable. Undantag: UDP som stoppas i den egna serverns kedja ut (t.ex. D4-nek) ger felet EPERM direkt i skriptet och syns som `avvisad`, med en `ZON-UT-DROP`-rad i loggen |

Nekade fall in mot elev-46 körs från **jump** över labbnätet (172.20.1.146). Jumps egen trafik filtreras inte, så SYN-paketet når elev-46 och det är elev-46:s regel som stoppar det. Nekade fall som körs från en teamkamrat i teamnätet stoppas redan i teamkamratens utgående kedja, vilket också är rätt enligt flödestabellen, men syns då i *källserverns* logg.

## Förberedelser

- Webbservern på tcp/80 finns redan. Lyssnare för F5: `sudo ncat -lk 443`.
- elev-24 lyssnar på tcp/8080 för F9 (`ncat -lk 8080`).
- Testfallen F4-till, F5-till och F4-nek körs från jump, som går ut på internet via eth0 och därför passerar elev-46:s molnbrandvägg.
- Skriptet och testfallen kopieras till varje källa som behövs, även jump: `scp -r elev-46 jump:` och `scp -r elev-46 student@elev-46:` från repot.

## Körning

```
# terminal 1 på elev-46 – fångst på teamnätet och labbnätet, utan egen SSH
mkdir -p bevis
sudo tcpdump -nn -i any -w bevis/elev-46-test.pcap 'not port 22 or net 10.40.1.0/24'

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
| F4-till | jump | oppen | – | | | | |
| F5-till | jump | oppen | – | | | | |
| F4-nek | jump | tyst | moln | | | | |
| 80-nek | jump | tyst | elev-46 in | | | | |
| F22-till | jump | oppen | – | | | | |
| F9-till | elev-46 | oppen | – | | | | |
| F9-nek | elev-46 | tyst | elev-46 ut | | | | |
| F11-nek-v4 | elev-46 | tyst | elev-46 ut | | | | |
| D3-till | elev-46 | oppen | – | | | | |
| D3-nek | elev-46 | tyst | elev-46 ut | | | | |
| D4-till | elev-46 | oppen | – | | | | |
| D4-nek | elev-46 | avvisad | elev-46 ut | | | | |
| D5-till | elev-46 | oppen | – | | | | |
| D5-nek | elev-46 | tyst | elev-46 ut | | | | |
| D7-till | elev-46 | oppen | – | | | | |
| D7-nek | elev-46 | tyst | elev-46 ut | | | | |

Avvikelser felsöks och testet körs om tills tabellen är stabil. Varje körning sparas som en egen `testprotokoll-elev-46-fran-<källa>-<tid>.csv` i `bevis/`.
