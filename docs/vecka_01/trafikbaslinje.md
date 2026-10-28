# Trafikbaslinje – nätverkstrafik

Jag har gått igenom mina trafikfångster i Wireshark och tcpdump för att se vilka enheter som kommunicerar, vilka protokoll och portar som används och hur ofta trafiken förekommer. Jag har delat upp materialet i trafikflöden för baslinjen, andra observationer från labben och en avvikelse från U1.4.

## Fångsttider

### U1.2

- **Fångstfil:** /home/student/U1.2-udp-sparad.pcap på elev-09.
- **Första paket:** 2026-10-12 kl. 16:38:42.705671.
- **Sista paket:** 2026-10-12 kl. 16:38:52.473826.
- **Tid från första till sista paketet:** Cirka 9,77 sekunder.
- **Resultat:** 40 paket fångades och inga paket tappades.

### U1.3

- **Fångstfil:** U1.3-lagerkartan.pcap.
- **Första paket:** 2026-10-07 kl. 10:29:14.
- **Sista paket:** 2026-10-07 kl. 10:29:20.
- **Tid från första till sista paketet:** 6 sekunder.

### U1.4

- **Fångstfil:** U1.4-avvikelsen.pcap.
- **Första paket:** 2026-10-08 kl. 11:00:47.
- **Sista paket:** 2026-10-08 kl. 11:12:45.
- **Tid från första till sista paketet:** 11 minuter och 58 sekunder.

Tiderna för U1.3 och U1.4 kommer från Wiresharks Capture File Properties. Tiderna för U1.2 kommer från tcpdump.

# Del 1 – Trafikbaslinje

Här beskriver jag de fyra trafikflöden som jag använder som baslinje.

## 1. SSH-kommunikation

- **Källa:** 172.20.1.2
- **Mål:** 172.20.1.109
- **Protokoll och port:** SSH över TCP, port 22.
- **Riktning:** Kommunikation i båda riktningarna.
- **Frekvens:** 5 konversationer och totalt 50 paket.
- **Användning:** Säker fjärrinloggning.
- **TCP/IP-lager:** Applikation och transport.
- **Belägg:** Conversations och Protocol Hierarchy i Wireshark.
- **Fångstfil:** U1.4-avvikelsen.pcap.

## 2. DNS-kommunikation

- **Källa:** 172.20.1.109
- **Mål:** 185.12.64.1
- **Protokoll och port:** DNS över UDP, port 53.
- **Riktning:** Fråga från källan och svar tillbaka.
- **Frekvens:** 11 konversationer och totalt 22 paket.
- **Användning:** Översätter domännamn till IP-adresser.
- **TCP/IP-lager:** Applikation och transport.
- **Belägg:** Paket 23–24 visar frågan efter log.sec.chas-lab.dev och svaret 46.224.108.117.
- **Fångstfil:** U1.4-avvikelsen.pcap.
- **Wireshark-filter:** dns

## 3. HTTP-kommunikation

- **Källa:** 172.20.1.109
- **Mål:** 46.224.108.117
- **Protokoll och port:** HTTP över TCP, port 80.
- **Riktning:** GET-förfrågningar från källan och svar tillbaka.
- **Frekvens:** 11 konversationer och totalt 110 paket.
- **Användning:** Kommunikation med en webbtjänst.
- **TCP/IP-lager:** Applikation och transport.
- **Belägg:** Paket 136 och 192 innehåller HTTP GET-förfrågningar med Host: log.sec.chas-lab.dev.
- **Fångstfil:** U1.4-avvikelsen.pcap.
- **Wireshark-filter:** http

## 4. NTP-kommunikation

- **Källa:** 172.20.1.109
- **Mål:** 185.12.64.2
- **Protokoll och port:** NTP över UDP, port 123.
- **Riktning:** Kommunikation i båda riktningarna.
- **Frekvens:** 16 paket, 8 i vardera riktningen.
- **Användning:** Synkronisering av tid.
- **TCP/IP-lager:** Applikation och transport.
- **Belägg:** Conversations och Protocol Hierarchy i Wireshark.
- **Fångstfil:** U1.4-avvikelsen.pcap.
- **Wireshark-filter:** ntp

# Del 2 – Övriga observationer från labben

De här observationerna kommer från U1.2 och U1.3. Jag har tagit med dem för att visa vad jag hittade i labben, men jag har inte räknat in dem i baslinjen eftersom jag inte har fastställt att de är vanlig trafik.

## 5. UDP-trafik från U1.2

- **Källa:** 172.20.1.10
- **Mål:** 172.20.1.109
- **Protokoll och portar:** UDP, målportarna 901, 902, 903 och 904.
- **Riktning:** Från CTF-servern till min server.
- **Frekvens:** 40 paket fångades totalt. Fyra paket gick till portarna 901–904, ett paket till varje port.
- **Användning:** När jag körde kontrollen för U1.2 skickades fyra paket med varsitt ord. Resten var brus.
- **Belägg:** Jag hittade orden samba på port 901, modell på port 902, etikett på port 903 och hjul på port 904.
- **Fångstfil:** /home/student/U1.2-udp-sparad.pcap på elev-09.
- **Nätverkskort:** eth1.
- **Filter vid fångst:** udp and host 172.20.1.10.

Jag sorterade orden efter målport i stället för den ordning paketen kom in. Då fick jag fram orden i rätt ordning och kunde få fram flaggan, som jag redan hade lämnat in.

## 6. ICMP-trafik från U1.3

- **Källa:** 172.20.1.58
- **Mål:** 172.20.1.109
- **Protokoll och port:** ICMP. ICMP använder ingen TCP- eller UDP-port.
- **Riktning:** Paket 63 var en Echo Request från källan till målet.
- **Frekvens:** 10 paket matchade filtret icmp.
- **Användning:** ICMP används bland annat för att kontrollera om en enhet går att nå.
- **TCP/IP-lager:** Internetlagret.
- **Belägg:** Paket 63 innehöll texten ”bricka”.
- **Fångstfil:** U1.3-lagerkartan.pcap.
- **Wireshark-filter:** icmp

## 7. TCP-trafik till port 9000 från U1.3

- **Källa:** 172.20.1.109
- **Mål:** 172.20.1.58
- **Protokoll och port:** TCP, källport 38703 och målport 9000 i paket 86.
- **Riktning:** Paket 86 gick från källan till målet.
- **Frekvens:** 31 paket matchade filtret tcp.port == 9000.
- **Användning:** Jag har inte fastställt vad trafiken användes till.
- **TCP/IP-lager:** Transportlagret.
- **Belägg:** Paket 86 hade RST-flaggan. TCP-strömmen innehöll texten ”havre”.
- **Fångstfil:** U1.3-lagerkartan.pcap.

# Del 3 – Avvikelse från U1.4: TCP port 4444

## Observerad trafik

- **Källa:** 172.20.1.109
- **Mål:** 203.0.113.230
- **Protokoll och port:** TCP, målport 4444.
- **Riktning:** Från 172.20.1.109 till 203.0.113.230.
- **Frekvens:** 1 konversation, 8 paket och 469 byte under cirka 0,19 sekunder.
- **Användning:** Inte fastställd.
- **TCP/IP-lager:** Transportlagret.
- **Belägg:** TCP Stream ID 10 innehöll Base64-kodad text som avkodades till ”lodjur stol smula kalender”.
- **Fångstfil:** U1.4-avvikelsen.pcap.
- **Wireshark-filter:** tcp.port == 4444

## Bedömning

Den här trafiken skiljer sig från de fyra flöden som jag har tagit med i baslinjen. Den använder TCP-port 4444 och innehåller kodad text som jag inte har kunnat koppla till någon känd tjänst.

Jag vet inte vad trafiken användes till och kan därför inte säga att den är skadlig. Jag har lagt den separat från baslinjen eftersom den ska kunna undersökas som en avvikelse.

# Sammanfattning

Jag har undersökt trafik från U1.2, U1.3 och U1.4. Jag har dokumenterat fyra trafikflöden i baslinjen och lagt övriga observationer i ett eget avsnitt. Trafiken till port 4444 finns separat som en avvikelse.

Jag har beskrivit det jag sett i fångsterna och varit tydlig med vad jag inte vet. På så sätt går det att följa mina observationer och se vilka belägg jag har använt.
