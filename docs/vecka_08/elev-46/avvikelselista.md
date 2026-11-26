# Avvikelselista – elev-46 (U8.1)

Tidsreferens: fångsten startar 2026-11-18 11:09 UTC
Tider nedan = sekunder från fångstens start.

| Tidpunkt | Flöde | Vad som avviker | Paketnummer | Säkerhet | Bedömning |
|---|---|---|---|---|---|
| 112-123 s | TCP SYN 172.20.1.110-> 172.20.1.146:många portar | sticker ut då det är 220 syn försök följt av rst från min server på olika portar på 11 sekunder | 91-536 | Hög | Angrepp, scanning, (T1046) |
| 128-135 s | 172.20.1.110-> 172.20.1.146: port 22 | 15 korta SSH sessioner mot samma adress och port | 539-690 | Hög | Angrepp, bruteforce, (T1110) |
| 135-152 s | 172.20.1.110-> 172.20.1.146: port 22 | En längre session  direkt efter dem 15 korta från samma källa. | 693-750 | Hög | Angrepp, lyckad inloggning (bekräftad i logg, U8.3), (T1078) |
| 140-141 s | 172.20.1.146-> 172.20.1.114: port 22 | Min server skickar SYN till en tredje värd på port 22. | 702-711 | Hög | Angrepp, lateral rörelse, (T1021) |
| 144-147 s | 172.20.1.146-> 185.12.64.1: port 53 | Domännamnet avviker trots att målet är den vanliga resolvern, långa base32 etiketter med sekvensnummer. | 716-738 | Hög | Angrepp, DNS tunnling, (T1048) |
| 0,3-175 s | 172.20.1.146-> 172.20.1.58: port 1514 | Min server skickar SYN paket var femte sekund till samma adress och port och får svar RST varje försök, pågår hela fångsten | 3-770 | Hög | Felkonfiguration, loggklient mot fel port (log tar bara emot på port 514/6514) |


## AI-domar

Prompt (maskerad, inga adresser): "Jag utreder en paketfångst. Värd A skickar SYN mot 220 portar på min server B under 11 s och får RST tillbaka på. Därefter 15 korta SSH sessioner från A till B på port 22, och sedan en längre session. Under den längre sessionen skickar B SYN till en tredje intern värd C på port 22, och därefter 7 DNS frågor med långa slumpmässiga etiketter till en okänd domän via den vanliga resolvern. Hela fångsten igenom skickar B SYN var femte sekund till loggservern på port 1514 och får RST. Föreslå visningsfilter och hypoteser om vad som har hänt." 

| Förslag | Dom | Skäl | Paketnummer |
|---|---|---|---|
| F1: `ip.src==A && tcp.flags.syn==1 && tcp.flags.ack==0` – skanningen | Stämmer | Jag ser alla 220 SYN från A mot olika portar på 11 s, filtret räcker för att se att det är en scanning. Detta filtret plockar också upp SYN från ssh sessionerna, för att isolera skanningen behövs `&& tcp.dstport !=22` | 91-693|
| F2: `tcp.port==22 && ip.addr==A` – SSH-sessionerna | Stämmer | Fungerar och plockar upp rätt paket, men fångar även skanningen, när den träffade port 22 blev det SYN, SYN-ACK och sedan RST från angriparen. | 241-243+ 539-750 |
| F3: `ip.src==B && tcp.dstport==22` – lateral rörelse | Stämmer | Den visar hela anslutningen mellan B och tredje parten |702-711 |
| F4: `dns.qry.type==16` – tunneln (TXT-frågor) | Stämmer | Visar alla TXT frågor och svar mot samma domän med konstiga, kodade namn alltså tunneln. Filtret visar både frågor och svar.| 714-745 |
| F5: `http.request.method=="POST"` – uppladdning över HTTP | Filtret stämmer, menfel i att uppladdning skulle skett över HTTP | 0 träffar, HTTP trafiken är okrypterad och innehåller ingen POST, 443 träffades bara av skanningen men fick RST, ingen uppladning över webben.| 0 |
| H1: A gjorde en portskanning, troligen med nmap | Skanning Ja, med nmap ogrundat.| 220 SYN mot olika portar på 11 s visar skanningen. Mönstret SYN, SYN-ACK, RST från angriparen visar en SYN skanning men inte med vilket verktyg | 91-536 |
| H2: A gissade lösenord mot SSH och lyckades till slut | Stämmer | 15 korta sessioner från A följt av en längre, Accepted password för samma källa och port finns i loggen som styrker den hypotesen. | 539-750 |
| H3: Angriparen hoppade vidare från B till C med SSH | Stämmer anslutning från B till C, ogrundat att anslutningen lyckades| B skickar SYN till C:22 under angriparens session. SSH är krypterat och sessionen var kort, och det finns ingen loggpost från C som visar att inloggningen lyckades | 702-711 |
| H4: Data fördes ut via DNS-tunneln, troligen /etc/shadow |exfiltration via dns Stämmer, från /etc/shadow är fel. | Etiketterna avkodades med base32 till fyra ord i sekvensordning, och bruset blir oläsligt så inget innehåll från /etc/shadow. | 716-738 |
| H5: 1514-trafiken är en bakdörr som ringer hem | Fel | Målet är den interna loggservern, flödet börjar före angreppet och pågår hela fångsten med jämn takt, och varje försök får RST utan att någon data skickas. Tyder på felkonfiguration (U8.4) | 3-770 |
