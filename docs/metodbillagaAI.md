# AI-användning

| Datum | Dokument | Vad AI användes till | Vem |
|---|---|---|---|
| 2026-10-12 | lagerkarta.md | Stöd vid sammanställning av TCP/IP-lagren och kontroll av protokoll och belägg från trafikanalysen | Gabriel |
| 2026-10-12 | checklista.md | Stöd vid strukturering av kontrollpunkter och förberedelser inför checkpointen | Gabriel |
| 2026-10-13 | Tillgangar.md | hjälp med struktur för tillgangar.md samt förslag på observationer utifrån vad jag själv sätt | Hugo|
| 2026-10-14 | adressplan.md | Stöd vid sammanställning och kontroll av uträkningar | Hugo |
| 2026-10-15 | zonforslag.png | Skapa zonskiss bilden utifrån teamets flöden och överskommelse | Hugo |
| 2026-10-21 | checklista-zero-trust.md | Stöd vid formulering av kontrollfrågor per Zero Trust-princip | Hugo |
| 2026-10-21 | reviderad-zonskiss.png | Skapa reviderad zonskiss utifrån ändringarna i markeringstabellen | Hugo |
| 2026-10-22 | flodestabell.md | Stöd vid jämförelse av trafikbaslinjen från vecka 1 och flödestabellen i vecka 3 | Hugo |
| 2026-10-22 | zoner-i-labbet.md | utkast tabell till hur teamets servrar ska representera zonerna i vecka 4 baserat på information från repot och gruppen | Hugo |
| 2026-10-26 | adressplan.md | Stöd vid omräkningen till 10.40.1.0/24. Teamet valde dimensionering och subnät och kontrollerade mot moln status | Gabriel, Hugo |
| 2026-10-26 | flodestabell.md | Stöd vid struktur (F-id, lager, D1–D7) och granskning. Portar, beslut och NTP-verifiering gjordes av teamet | Gabriel, Hugo |
| 2026-10-26 | reviderad-zonskiss2.0.png | Stöd vid uppdatering av skissen enligt teamets beslut | Hugo |
| 2026-10-26 | markeringstabell.md, zoner-i-labbet.md | Stöd vid uppdatering av prefix och hänvisningar till flödestabellen | Hugo |
| 2026-10-26 | Hela repot | Kontroll av att dokumenten och länkarna stämmer med varandra | Gabriel, Hugo |
| 2026-10-29 | testfall.csv | Tog fram testfallslistan för elev-46 utifrån flödestabellen. | Hugo |
| 2026-10-29 | test.sh | AI som stöd för att bygga vidare på förövningens test.sh ut efter min egna testfalls lista | Hugo |
| 2026-10-29 | zon.nft (elev-09) | AI som stöd vid uppbyggnad av mitt regelverk (loggregel, policy drop, F22 ping från jump); jag byggde och verifierade reglerna själv och kontrollerade med nft -c | Gabriel |
| 2026-10-29 | testprotokoll (elev-09) | Körde test.sh och tcpdump på min server och sparade bevisen i Bevis/; AI som stöd vid tolkning av utfallen (tyst / avvisad / nekad) | Gabriel |
| 2026-11-02 | zon.nft (elev-46) | Granskning mot flödestabellen. AI hittade att F22 (ping från jump) saknades. Jag lade till regeln och verifierade den med ping | Hugo |
| 2026-11-02 | testfall.csv, bevis-manuella.txt (D1-nek) | AI påstod att TCP som stoppas i egen kedja ut ger "avvisad". Omkörning med returkod (rc=124) visade "tyst". Rättat efter vår egen kontroll | Hugo, Stef |
| 2026-11-04 | loggstrategi.md | Stöd vid tolkning av kommandoutskrifter (rotation, tidsformat). All data hämtad av mig från elev-46 | Hugo |
| 2026-11-04 | loggstrategi.md | Gjorde om google docs tabell till md format för att fungera i github repot. | Hugo |
| 2026-11-04 | rsyslog/nftables-konfig | AI som stöd för konfig och uträkningar; jag kontrollerar mot man-sidorna och rsyslogd -N1 / nft -c, och har förenklat eller sagt emot när förslaget varit fel eller för krångligt | Gabriel |
| 2026-11-05 | 90-logg.conf | AI skrev utkastet utifrån Peters referens i föreläsning 6 och förklarade varje parameter. Jag gick igenom och anpassade filen, installerade den, felsökte SELinux-felet på CA-filen med AI och verifierade med rsyslogd -N1 och testhändelser via loggsök | Hugo |
| 2026-11-05 | skyddsbeskrivning.md | Jag tog fram underlaget och beläggen (rättigheter, sudo-gruppen, SSH-försöket mot loggservern) och lät AI strukturera texten efter studieguidens fyra rubriker. Jag rättade påståenden som saknade belägg och jämförde mot teamets version | Hugo |
| 2026-11-05 | verifieringsanteckning.md | AI sammanställde tabellen utifrån mina utskrifter från loggsök. Jag körde testerna och kontrollerade raderna | Hugo |
| 2026-11-11 | nedbrytning_elev-46.md | Stöd vid förklaring av DQL-sökningar, ai gjorde om min textfil till md format. | Hugo |
