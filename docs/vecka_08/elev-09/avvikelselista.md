## Alla tider i UTC, från fångsten.
| Tid (UTC) | Flöde | Vad avviker | Paket | Säkerhet | Bedömning |
|---|---|---|---|---|---|
| 11:06:57 | MIN-SERVER → LOG:1514 | 38 SYN mot samma port, RST varje gång, var femte sekund. Fel port, log tar emot på 514 och 6514 | 5– | hög, jämn takt, ett mål och en port | felkonfiguration |
| 11:08:58 | ANGRIPARE → MIN-SERVER | SYN mot många portar, en gång var | 95– | hög, en källa mot många portar på kort tid | angrepp (T1046) |
| 11:09:04 | ANGRIPARE → MIN-SERVER:22 | 17 SYN mot port 22, korta sessioner, ca 1 000 byte och 0,2 sekunder | 337– | hög, många försök från samma källa | angrepp (T1110) |
| 11:09:21 | ANGRIPARE → MIN-SERVER:22 | En stor session, 5 382 byte och 17 sekunder, källport 55984 | 695 | hög, bekräftad i loggen: Accepted password 11:09:23, samma källa och port | angrepp (T1078) |
| 11:09:30 | MIN-SERVER → resolvern | 14 DNS-frågor med långa namn till samma domän, base32 i etiketterna | 706–738 | hög, avkodade till fyra ord | angrepp (T1048) |

## Berättelse

Alla tider i UTC, från fångsten.

Steg 1, 11:08:58: Angriparen skannar min server och försöker på flera olika portar (paket 95–, T1046).

Steg 2, 11:09:04: Angriparen försöker brute forca sig in via SSH på port 22 (paket 337–, T1110).

Steg 3, 11:09:21: Angriparen lyckas logga in med ett giltigt konto, en lång SSH-session (paket 695, T1078).

Steg 4, 11:09:30: Angriparen för ut data från min server via en DNS-tunnel (paket 706–738, T1048).

Lateral rörelse finns inte i min fångst. Trafiken till log på port 1514 är en felkonfiguration och inte en del av angreppet.

## Tidslinje

Alla tider i UTC. Fångstens tid från tshark -t ud, loggens tid från full_log.

| Tid (UTC) | Källa | Typ | Händelse | Bevis |
|---|---|---|---|---|
| 11:06:57 | pcap | observation | MIN-SERVER skickar SYN till LOG på port 1514 var femte sekund, får RST varje gång | paket 5– |
| 11:06:57 | – | slutsats | Felkonfigurerad loggklient, inte en del av angreppet | jämn takt, ett mål, en port |
| 11:08:58 | pcap | observation | ANGRIPARE skickar SYN mot många portar på MIN-SERVER, en gång per port. RST tillbaka från de flesta, SYN/ACK från 22 och 80 | paket 95– |
| 11:08:58 | – | slutsats | Någon testar flera portar för att se var det går att ta sig in: skanning (T1046) | en källa mot många portar på kort tid |
| 11:09:04 | pcap | observation | ANGRIPARE öppnar 17 korta SSH-sessioner mot MIN-SERVER på port 22, ca 1 000 byte och 0,2 sekunder var | paket 337– |
| 11:09:04 | – | slutsats | Många försök från samma källa: brute force (T1110) | 17 korta sessioner på några sekunder |
| 11:09:21 | pcap | observation | ANGRIPARE öppnar en SSH-session mot MIN-SERVER från källport 55984, 5 382 byte och 17 sekunder, mycket längre än de andra | paket 695 |
| 11:09:23 | logg | observation | sshd: Accepted password for student från ANGRIPARE port 55984 | loggrad i scenario.log |
| 11:09:23 | – | slutsats | Angriparen lyckades logga in med kontot student: lyckad inloggning (T1078). Paket och logg är samma händelse | samma källa och port, 2 sekunder mellan SYN och Accepted |
| 11:09:30 | pcap | observation | MIN-SERVER skickar 14 DNS-frågor till resolvern med långa namn till samma domän. Etiketterna avkodas från base32 till ord | paket 706–738 |
| 11:09:30 | – | slutsats | Angriparen för ut data från servern gömd i DNS-frågor: exfiltrering via DNS-tunnel (T1048) | etiketterna avkodas till ord, frågorna går ut från MIN-SERVER |

## AI-domar

| Förslag | Dom | Skäl | Paketnummer |
|---|---|---|---|
| Filter: SYN från angriparen | stämmer | 236 träffar, visar skanningen och de 17 SSH-försöken | 95–, 337– |
| Filter: vilka portar svarade med SYN/ACK | stämmer | Servern svarade öppen på port 22 (17 gånger) och 80 (1 gång) | |
| Filter: conv,tcp för SSH-sessionerna | stämmer | Visar SSH-sessionerna, en är mycket större än de andra, 5 382 byte | 695 |
| Filter: ssh.protocol, vilket SSH-program | stämmer | Visar OpenSSH 8.7 och 9.6. Inget attackverktyg syns, klienten ser ut som vanlig OpenSSH | |
| Filter: DNS-frågorna | stämmer | Visar 14 frågor med långa namn till samma domän | 706–738 |
| Hypotes 1: portskanning, troligen nmap -sS | stämmer (skanning), ogrundat (nmap) | SYN mot många portar från en källa bevisar skanning. Fångsten kan inte visa vilket verktyg | 95– |
| Hypotes 2: brute force mot SSH | stämmer | 17 korta SSH-sessioner från samma källa på kort tid. Antal och längd syns, inte lösenorden | 337– |
| Hypotes 3: lyckad inloggning | ogrundat | SSH är krypterat, fångsten kan inte avgöra. Bekräftad i loggen: Accepted password 11:09:23 | 695 |
| Hypotes 4: exfiltrering via DNS | stämmer | Frågorna går från min server ut till samma domän. Namnen är base32 och avkodas till ord | 706–738 |
| Alternativ: godkänt penetrationstest | ogrundat | Fångsten kan inte visa om någon har gett lov. Det avgörs av avtal, inte av paket | |
| Alternativ: vanlig telemetri | fel | Etiketterna avkodas till ord med sekvensnummer, blandat med brus. Domännamnet är kamouflage | 706–738 |

## Korrelation och luckor

Alla tider i UTC. Fångstens tid från tshark -t ud, loggens tid från full_log.

| Steg | Nätverksbevis | Loggbevis | Tidsstämpel | Lucka | Källa som hade behövts | Varför den saknades | Detektion |
|---|---|---|---|---|---|---|---|
| 1. Skanning (T1046) | Paket 95–, SYN mot många portar | Ingen | 11:08:58 (paket) | Ja | Paketfiltrets logg (ZON-IN-DROP) | Loggregeln har limit rate 10/minute burst 5. Den bekräftar att något händer, men visar inte en skanning mot många portar på kort tid | Zonöverträdelse borde ha larmat, men inga drop-rader kom |
| 2. Brute force (T1110) | Paket 337–, 17 SYN mot port 22 | Ingen | 11:09:04 (paket) | Ja | sshd (authpriv) via rsyslog | Konfigurationen skickar *.info, men inga Failed password-rader kom fram för scenariot | Brute force-monitorn borde ha larmat, men inga Failed-rader kom |
| 3. Lyckad inloggning (T1078) | Paket 695, källport 55984 | Accepted password for student, port 55984 | 11:09:21 (paket), 11:09:23 (logg) | Nej | – | – | Ingen detektion finns för lyckad inloggning |
| 4. DNS-tunnel (T1048) | Paket 706–738, 14 frågor med långa namn | Ingen | 11:09:30 (paket) | Ja | Logg över DNS-frågor, i resolvern eller brandväggen | D3 tillåter DNS till resolvern utan loggning, och servern loggar inte sina DNS-frågor | Ingen detektion finns för DNS |

## Ändringsförslag

| Lucka | Ändringsförslag | Typ | Rad i tidslinjen |
|---|---|---|---|
| 1. Skanning | Ny nftables-regel med meter som loggar källor med fler än 20 nya anslutningsförsök per sekund, med prefixet ZON-SKANNING. Detektion i Wazuh på prefixet | regel och detektion | 11:08:58 |
| 2. Brute force | sshd med LogLevel VERBOSE för fler detaljer per försök. Ändra brute force-monitorn så att den räknar authentication_failed per data.srcip, till exempel fler än 5 på 1 minut från samma källa | loggnivå och regel | 11:09:04 |
| 4. DNS-tunnel | Lokal resolver (unbound) på servern som loggar varje DNS-fråga med namnet. Raderna skickas till log via rsyslog. Detektion i Wazuh på långa namn, till exempel över 25 tecken, eller många frågor till samma domän på kort tid | ny källa och detektion | 11:09:30 |
