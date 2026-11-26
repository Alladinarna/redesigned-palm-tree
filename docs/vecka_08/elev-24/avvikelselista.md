# Avvikelselista – elev-24 (U8.1)

Milstolpe v08 "Utredd incident med tidslinje". Alla tider i UTC, från fångsten.

## Tidslinje – nätverk ↔ logg

| # | Tid (UTC) | Steg / ATT&CK | Nätverksbevis (pcap) | Loggbevis | Status |
|---|-----------|---------------|----------------------|-----------|--------|
| 0 | 11:07:10 → | Felkonfiguration: loggklient mot .58:1514, RST var 5:e s | #5–#624 (38 SYN/RST) | – (loggarna når inte fram, vilket är själva felet) | belagd |
| 1 | 11:09:08–11:09:20 | Skanning – T1046 | #93–#537, .108 → .124 port 12–1023 | ingen (inget loggar SYN mot stängda portar) | **lucka 1** |
| 2 | 11:09:29 | Lyckad inloggning – T1078 | #543–#600, .108:52984 → .124:22 | `2026-11-18T11:09:30.366 UTC sshd[59269]: Accepted password for student from 172.20.1.108 port 52984` (nonce=bb58deda), Wazuh regel 5715, nivå 3 – **inget larm** | belagd, **lucka 4** |
| 3 | 11:09:34 | Lateral rörelse – T1021 | #552, .124:45098 → .112:22 | ingen post från .112 | **lucka 2** |
| 4 | 11:09:38–11:09:42 | Exfiltration via DNS – T1048 | #564–#596, TXT mot `*.sync.telemetri-app.net` | ingen (DNS-frågor loggas inte) | **lucka 3** |

## AI-domar

| AI-förslag | Dom | Kommando/filter som avgjorde | Utfall |
|------------|-----|------------------------------|--------|
| "Det finns brute force mot SSH (T1110)" | **fel** | SSH-flöden .108 → .124:22 | bara 1 SYN-kontroll (#462) + 1 session (#543), inga upprepade korta sessioner |
| Filter `dns.qry.type == 16` för att hitta tunneln | **stämmer** | samma filter | 14 TXT-frågor #564–#596 |
| "Flödet mot 1514 är en skanning" | **fel** | `tcp.dstport==1514` | ett mål, en port, jämn takt på 5 s → trasig loggklient (bekräftat av U8.4) |
| "Angriparen laddade upp data via HTTPS" | **ogrundat** | `tcp.port==443` | ingen 443-trafik alls i fångsten; exfiltrationen gick via DNS |
| "Angriparen använde ett giltigt konto" | **stämmer** (efter U8.3) | sshd `Accepted` i wazuh-archives | posten matchar tid, källa och port |

## Ändringsförslag per lucka

| Lucka | Ändring | Typ |
|-------|---------|-----|
| 0 – loggklienten skickar till 1514 | Rätta vidarebefordran till loggserverns riktiga port (log tar emot på **514/6514**, inte 1514). Lägg dessutom en kontroll i verifieringsskriptet: varnar om `ss -tn` visar SYN-SENT/RST mot loggservern. Kontrollerat 2026-11-24: den riktiga servern är rätt konfigurerad (`/etc/rsyslog.d/90-logg.conf:22` → `target="172.20.1.58" port="6514" protocol="tcp"`), så felet finns bara i scenariot. | loggstrategi |
| 1 – skanningen syns inte | Lägg en nftables-regel som loggar nya inkommande anslutningar till stängda portar med rate limit: `ct state new limit rate 10/second log prefix "NFT-SCAN "`. Lägg en Wazuh-regel som larmar när en källa träffar >20 portar på 10 s. | loggstrategi |
| 2 – lateral SSH .124 → .112 syns inte | **Segmentering:** tillåt tcp/22 in till servrarna **endast från jump** (`ip saddr <jump> tcp dport 22 accept`, resten `drop` + `log`). **Logg:** vidarebefordra `authpriv.*` från alla servrar, plus en detektionsregel för SSH mellan interna servrar som inte kommer från jump. | segmentering + logg |
| 3 – DNS-tunneln syns inte | Tvinga DNS via en intern resolver med frågeloggning. Blockera direkt utgående 53 till externa resolvrar i paketfiltret. Larma på TXT-frågor och på långa eller många unika subdomäner mot samma domän. | segmentering + logg |
| 4 – lyckad inloggning från intern icke-jump-adress gav inget larm | Inloggningen från .108 syntes i loggen men fick bara regel 5715, nivå 3, så ingen larmade. Lägg en egen Wazuh-regel som bygger på 5715 och höjer nivån när `data.srcip` **inte** är jump. En lyckad SSH-inloggning som inte kommer via jump ska alltid larma. | loggstrategi |
