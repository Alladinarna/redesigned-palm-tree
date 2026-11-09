# Testprotokoll – elev-24 (Serverzon)

Varje rad i [spårbarhetslistan](sparbarhetslista.md) testas med ett tillåtet och ett nekat fall i [testfall.csv](testfall.csv). Testerna körs med [test.sh](test.sh) på den server som står som källa (elev-09, elev-24, elev-46, jump). En samtidig trafikfångst visar *vem* som nekade: ett utfall ensamt räcker inte, eftersom `tyst` också kan bero på fel adress eller att avsändarens egen utgående kedja kastade paketet.

## Förväntade paketmönster

| Utfall | Vad fångsten ska visa |
|---|---|
| oppen | SYN → SYN-ACK → ACK (eller DNS-/NTP-/ICMP-svar) |
| tyst | Upprepade SYN utan svar, och en `ZON-IN-DROP` eller `ZON-UT-DROP`-rad i `journalctl -k` på den server som står i kolumnen *nekas av* (eller ingen loggrad alls om det är molnbrandväggen) |
| avvisad | SYN → RST, eller ICMP destination unreachable. Undantag: UDP som stoppas i den egna serverns kedja ut (t.ex. D4-nek) ger felet EPERM direkt i skriptet och syns som `avvisad`, med en `ZON-UT-DROP`-rad i loggen |

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
bash test.sh testfall.csv      # körrättigheten följer inte med scp från Windows

# efteråt på den server som ska ha nekat
journalctl -k -g ZON- --since "-15 min"
```

## Nollmätning före regelverket

Skriptet kördes på elev-24 2026-10-26T07:45Z, innan regelverket laddats och innan teamnätet fanns: [bevis/testprotokoll-elev-24-fore-regelverk.csv](Bevis/testprotokoll-elev-24-fore-regelverk.csv). Den kördes med de adresser som gällde före Hugos adressplan (elev-38 = 10.40.1.210 i stället för 10.40.1.162), vilket inte påverkar resultatet eftersom teamnätet inte fanns än.

- De nekade fallen **D3-nek, D7-nek** gav `oppen` och **D5-nek** gav `avvisad` (loggservern svarar RST på tcp/9000). Utan regelverk släpps alltså trafiken ut. När samma fall ger `tyst` efter att regelverket laddats är det regelverket som stoppar dem, inte en fel adress eller en tjänst som saknas.
- **10-till** (i dag F10-till) gav `tyst` eftersom elev-38 ännu inte är kopplad till teamnätet. Det är ett exempel på ett nekat utfall som inte bevisar något om reglerna.
- Tillåtna driftflöden (D3, D4, D5, D7) gav `oppen`, så testfallen fungerar.

## Resultat

Första körningen efter att regelverket laddats 2026-10-28 07:48Z, från elev-24: [bevis/testprotokoll-elev-24-fran-elev-24-20261028T074858Z.csv](Bevis/testprotokoll-elev-24-fran-elev-24-20261028T074858Z.csv). Ingen trafikfångst gjordes vid den körningen. Loggraderna är hämtade med `loggsök` på jump. Fallen från jump, elev-09 och elev-46 körs på workshop 2 (torsdag 29/10).

**Omstartstest:** elev-24 startades om 2026-10-28 07:58:40Z. Samma testfall kördes 08:00:42Z med samma utfall: [bevis/testprotokoll-elev-24-fran-elev-24-20261028T080042Z-efter-omstart.csv](Bevis/testprotokoll-elev-24-fran-elev-24-20261028T080042Z-efter-omstart.csv). (Den körningen använde den äldre testfall.csv där D4-nek förväntades `tyst`, därför står AVVIKER i filen.) D4-nek blev `avvisad`, vilket visar att det var det nya regelverket med låst NTP som laddades vid uppstarten. Det gamla släppte all udp/123 ut på eth0. Loggraderna för D4-nek och D5-nek kom fram till loggservern efter omstarten (`loggsök`, 08:00:48Z). Regelverket och loggningen överlever alltså en omstart.

| Id | Källa | Förväntat | Nekas av | Faktiskt | Paket i fångsten | Loggrad | Resultat |
|---|---|---|---|---|---|---|---|
| D1-till | jump | oppen | – | | | | |
| 80-nek | jump | tyst | elev-24 in | | | | |
| F22-till | jump | oppen | – | | | | |
| F22-nek | elev-46 | tyst | elev-46 ut | | | | |
| F8-till | elev-09 | oppen | – | | | | |
| F8-nek | jump | tyst | elev-24 in | | | | |
| F9-till | elev-46 | oppen | – | | | | |
| F9-nek | jump | tyst | elev-24 in | | | | |
| F9-nek-intern | elev-46 | tyst | elev-46 ut | | | | |
| F10-till | elev-24 | oppen | – | avvisad | | – | AVVIKER: snabbt nej (23 ms) från elev-38, alltså släppte elev-24 ut paketet. elev-38 saknar lyssnare eller regel på tcp/5432. Körs om |
| F10-nek | elev-24 | tyst | elev-24 ut | tyst | | ej kontrollerad | OK |
| D3-till | elev-24 | oppen | – | oppen | | – | OK |
| D3-till-tcp | elev-24 | oppen | – | oppen | | – | OK |
| D3-nek | elev-24 | tyst | elev-24 ut | tyst | | ej kontrollerad | OK |
| D4-till | elev-24 | oppen | – | oppen | | – | OK |
| D4-nek | elev-24 | avvisad | elev-24 ut | avvisad | | `ZON-UT-DROP OUT=eth0 DST=185.12.64.2 DPT=123` (07:49:04Z) | OK |
| D5-till | elev-24 | oppen | – | oppen | | – | OK |
| D5-nek | elev-24 | tyst | elev-24 ut | tyst | | `ZON-UT-DROP OUT=eth1 DST=172.20.1.58 DPT=9000` (07:49:04Z) | OK |
| F12-nek-v4 | elev-24 | tyst | elev-24 ut | tyst | | ej kontrollerad | OK |
| D7-till | elev-24 | oppen | – | oppen | | – | OK |
| D7-nek | elev-24 | tyst | elev-24 ut | tyst | | ej kontrollerad | OK |

Avvikelser felsöks och testet körs om tills tabellen är stabil. Varje körning sparas som en egen `testprotokoll-elev-24-fran-<källa>-<tid>.csv` i `bevis/`.

## Vecka 5: D5 flyttad till tcp/6514 (TLS)

Regelverket laddades om med `ladda-zon.sh` 2026-11-02 cirka 08:06Z (D5 släpper tcp/6514 mot 172.20.1.58 i stället för tcp/514). En ny session via jump fungerade och nödbromsen stoppades. `test.sh` kördes 08:07:08Z från elev-24: [bevis/testprotokoll-elev-24-fran-elev-24-20261102T080708Z.csv](Bevis/testprotokoll-elev-24-fran-elev-24-20261102T080708Z.csv).

| Id | Förväntat | Faktiskt | Resultat |
|---|---|---|---|
| D5-till (tcp/6514) | oppen | oppen (9 ms) | OK |
| D5-nek-klartext (tcp/514) | tyst | tyst (3006 ms) | OK |
| D5-nek (tcp/9000) | tyst | tyst | OK |
| F10-till | oppen | avvisad | AVVIKER, samma som 28/10 (elev-38 svarar med nej på tcp/5432) |

Övriga fall från elev-24 gav samma utfall som 28/10. Loggrad för en nekad anslutning över TLS, mottagen på log: `mottaget 2026-11-02T08:13:00.261Z TLS | 2026-11-02T08:13:00.023266+00:00 172.20.1.124 elev-24 kernel ZON-UT-DROP IN= OUT=eth2 SRC=10.40.1.98 DST=10.40.1.146 ... DPT=22 ... SYN` (`loggsök ZON-UT-DROP`).

## Checkpoint milstolpe 4: full körning, två gånger i rad, fångst och omstart (2026-11-02)

**Fångst:** `tcpdump -nn -i any` på elev-24 08:25:45–08:27:20Z. Filtret var `not ((port 22 or port 6514) and tcp[tcpflags] & (tcp-syn|tcp-rst|tcp-fin) == 0)`, så att SSH och TLS bara kom med som handskakningar. 126 paket: [bevis/elev-24-full-20261102T0825Z.pcap](Bevis/elev-24-full-20261102T0825Z.pcap).

**Körning 1 och 2:** först från jump, sedan från elev-24. Varje körning sparades som en egen CSV.

| Körning | Från jump | Från elev-24 |
|---|---|---|
| 1 | [08:25:53Z](Bevis/testprotokoll-elev-24-test-fran-jump-20261102T082553Z.csv) | [08:26:06Z](Bevis/testprotokoll-elev-24-fran-elev-24-20261102T082606Z.csv) |
| 2 | [08:26:23Z](Bevis/testprotokoll-elev-24-test-fran-jump-20261102T082623Z.csv) | [08:26:36Z](Bevis/testprotokoll-elev-24-fran-elev-24-20261102T082636Z.csv) |

Båda körningarna gav samma faktiska utfall på alla rader. F22-till (ping från jump) gav 2 av 2 svar båda gångerna.

| Id | Förväntat | Faktiskt (båda körningarna) | I fångsten | Loggrad på elev-24 (`journalctl -k -g ZON-`) | Resultat |
|---|---|---|---|---|---|
| D1-till | oppen | oppen | – (SSH-handskakning) | – | OK |
| 80-nek | tyst | tyst | Upprepade SYN `172.20.1.2 > 172.20.1.124.80`, inget svar | `ZON-IN-DROP IN=eth1 SRC=172.20.1.2 ... DPT=80` | OK |
| F22-till | oppen | oppen | – | – | OK |
| F8-nek | tyst | tyst | Upprepade SYN till `.443`, inget svar | `ZON-IN-DROP ... DPT=443` | OK |
| F9-nek | tyst | tyst | Upprepade SYN till `.8080`, inget svar | `ZON-IN-DROP ... DPT=8080` | OK |
| F10-till | oppen | avvisad | `10.40.1.98 > 10.40.1.162.5432 [S]` följt av `10.40.1.162.5432 > 10.40.1.98 [R.]` efter 4 ms | – | AVVIKER, se nedan |
| F10-nek | tyst | tyst | – | `ZON-UT-DROP OUT=eth2 DST=10.40.1.162 DPT=22` | OK |
| D3-till, D3-till-tcp, D4-till, D7-till | oppen | oppen | – | – | OK |
| D3-nek | tyst | tyst | – | `ZON-UT-DROP OUT=eth0 DST=8.8.8.8 DPT=53` | OK |
| D4-nek | avvisad | avvisad | – | `ZON-UT-DROP OUT=eth0 DST=185.12.64.2 DPT=123` (körning 1) | OK |
| D5-till (6514) | oppen | oppen | – | – | OK |
| D5-nek-klartext (514) | tyst | tyst | – | `ZON-UT-DROP OUT=eth1 DST=172.20.1.58 DPT=514` | OK |
| D5-nek (9000) | tyst | tyst | – | ingen rad i fönstret | OK |
| D7-nek | tyst | tyst | – | `ZON-UT-DROP OUT=eth0 DST=46.224.108.117 DPT=80` | OK |

I körning 2 saknas loggraden för D4-nek. Loggregeln i nftables har `limit rate 10/minute`. Att det är begränsningen som gjorde att raden saknas är inte kontrollerat.

D7-nek visar att `log.sec.chas-lab.dev` från elev-24 slås upp till den publika adressen 46.224.108.117, och att anslutningen stoppas i kedjan ut på eth0.

**Avvikelsen F10-till: var låg felet?** Felet ligger varken i elev-24:s regel eller i testfallet. Fångsten visar att elev-24 skickar SYN ut på eth2 (regeln F10 i kedjan ut släpper den) och att **elev-38 svarar med RST**. Förväntningen `oppen` förutsätter att något lyssnar på tcp/5432 på elev-38. Om elev-38 saknar lyssnare eller har en reject-regel är inte kontrollerat från elev-24. Det kontrolleras på elev-38.

**Omstart:** elev-24 startades om 08:27:48Z och var uppe igen 08:27:58Z.

| Kontroll efter omstarten | Resultat |
|---|---|
| `systemctl is-active nftables rsyslog auditd chronyd` | active active active active |
| `nft list ruleset` | 11 regler med F- eller D-id, D5 på tcp/6514 |
| `auditctl -l` | De två `root-cmd`-reglerna |
| `chronyc tracking` | Leap status Normal |
| `test.sh` från elev-24 08:28:26Z | Samma utfall som före omstarten: [bevis/testprotokoll-elev-24-fran-elev-24-20261102T082826Z-efter-omstart.csv](Bevis/testprotokoll-elev-24-fran-elev-24-20261102T082826Z-efter-omstart.csv) |
| `test.sh` från jump 08:28:43Z | D1-till OK och inga avvikelser enligt utskriften. CSV-filen raderades på jump innan den kopierades och finns inte i bevis |

**Molnbrandväggen** (`moln brandvägg regel lista` på jump, 2/11 cirka 08:24Z):

```
  1  out tcp  443         0.0.0.0/0            F20 paketuppdateringar dnf
  2  out udp  123         213.239.239.164/32   F19 NTP ntp.hetzner.com (D4)
  3  out udp  123         213.239.239.165/32   F19 NTP ntp.hetzner.com (D4)
  4  out udp  123         213.239.239.166/32   F19 NTP ntp.hetzner.com (D4)
```

Det stämmer med [molnbrandvagg-elev-24.md](molnregler.md). `moln status` visar teamnätet 10.40.1.0/24 med alla sju subnät och elev-24 kopplad som 10.40.1.98.

## D5 låst till labbnätet (eth1), 2026-11-02 08:37Z

**Bakgrund (observerat vid omstarten 08:27Z):** efter omstarten låg två anslutningar från rsyslog mot `172.20.1.58:6514` i `SYN-SENT` med avsändaradressen 91.99.144.137 (eth0). D5-regeln saknade då villkor för gränssnitt, så värden släppte ut paketen på eth0.

**Ändring:** D5-regeln i [elev-24-zon.nft](elev-24-zon.nft) blev `ip daddr $LOG oifname "eth1" tcp dport 6514 accept`. Det gick till så här:
1. `nft -c -f` gav inga fel.
2. Regelverket laddades med `ladda-zon.sh` 08:37Z.
3. En ny session via jump fungerade 08:37:29Z, och nödbromsen stoppades.
4. sha256 för `/etc/nftables/zon.nft` var samma som för repots fil (`61c9151a…071e`).

| Körning | Från elev-24 | Från jump | Utfall |
|---|---|---|---|
| Före omstart | [08:37:50Z](Bevis/testprotokoll-elev-24-fran-elev-24-20261102T083750Z.csv) | [08:38:07Z](Bevis/testprotokoll-elev-24-test-fran-jump-20261102T083807Z.csv) | Samma som 08:25Z. Bara F10-till avviker (se ovan) |
| Efter omstart | [08:41:49Z](Bevis/testprotokoll-elev-24-fran-elev-24-20261102T084149Z-efter-omstart.csv) | [08:42:06Z](Bevis/testprotokoll-elev-24-test-fran-jump-20261102T084206Z-efter-omstart.csv) | Samma |

**Omstart 08:38:45Z** (uppe igen 08:38:54Z). Efter omstarten var nftables, rsyslog, auditd och chronyd `active`, sha256 för `/etc/nftables/zon.nft` var oförändrad och de två `root-cmd`-reglerna fanns kvar.

**Vad ändringen gjorde (journalen efter omstarten):**

| Tid (UTC) | Händelse |
|---|---|
| 08:39:05.32 | rsyslog startar |
| 08:39:05.65 | `ZON-UT-DROP IN= OUT=eth0 SRC=91.99.144.137 DST=172.20.1.58 ... DPT=6514 SYN`, två anslutningar. Regeln stoppar nu paketen på eth0 och loggar dem. Fyra sådana rader under omstarten |
| 08:39:07.50 | `dhclient: bound to 172.20.1.124` (eth1) |
| 08:39:25 | `ss`: de två anslutningarna ligger fortfarande i `SYN-SENT` |
| 08:41:14.13 | rsyslog: `omfwd ... suspending action`, följt av `resumed`. Anslutningen går upp via eth1 (`172.20.1.124 → 172.20.1.58:6514 ESTAB`) |

**Resultat:** paketen går inte längre ut på eth0. Fördröjningen blev däremot inte kortare: cirka 128 s (08:39:05.65–08:41:14.13), att jämföra med cirka 130 s vid omstarten 08:27Z. När TCP-paketet stoppas i kedjan ut fick anslutningen inget fel direkt, utan kärnan fortsatte skicka SYN igen (`net.ipv4.tcp_syn_retries = 6`). Inga rader saknades: `omstart2-elev-24-20261102T083925Z` skapades 08:39:25Z och togs emot 08:41:14Z.
