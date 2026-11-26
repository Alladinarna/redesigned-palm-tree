# Baslinje-luckor – elev-24 (U8.1)

Tre saker teamets trafikbaslinje från vecka 1 (`docs/vecka_01/trafikbaslinje.md`) inte säger något om, jämfört med min scenariofångst U8.1.

1. Min server: Baslinjen bygger på fångster från 172.20.1.109 (U1.2–U1.4, 7–12 oktober). Min server 172.20.1.124 finns inte med. Den säger därför inget om vad som är normalt för min server, till exempel de inkommande HTTP-anropen mot port 80 från .101, .103, .107, .110 och .117 i fångsten. Baslinjens HTTP-flöde går åt andra hållet, från .109 ut till 46.224.108.117.

2. Loggtrafik: Baslinjen har fyra flöden: SSH, DNS, HTTP och NTP. Det finns ingen loggvidarebefordran i den, eftersom centralloggningen kom först vecka 5. Den kan därför inte säga om min servers SYN mot 172.20.1.58:1514 var femte sekund är normalt. Det avgjordes med U8.4 och loggserverns riktiga portar (514 och 6514), inte med baslinjen.

3. Innehållet i DNS och SSH: Baslinjen anger bara mål och mängd. DNS går till 185.12.64.1 (11 konversationer, 22 paket) och SSH går från 172.20.1.2 till .109 (5 konversationer, 50 paket). Den säger inget om vilka namn, frågetyper eller namnlängder som är normala, och inget om SSH mellan interna servrar. TXT-frågorna mot `*.sync.telemetri-app.net` och SSH från min server till 172.20.1.112 kan alltså inte bedömas mot baslinjen. Där blir kategorin "kan inte avgöras".
