# Filter – elev-24 (U8.1)

Mina fem visningsfilter. Resultaten är körda med tshark 3.4.10 på min server mot min fångst `U8.1-scenario.pcap` (624 paket, 2026-11-18 11:07:06–11:10:15 UTC). Min server är 172.20.1.124.

1. `tcp.flags.syn==1 && tcp.flags.ack==0`
Hittar: nya anslutningsförsök, SYN utan ACK. Många från en källa mot många portar är skanning.
I min fångst: 265 träffar. 221 kommer från 172.20.1.108 mot 220 olika portar (#93–#543), alltså skanningen. 38 kommer från min server mot 172.20.1.58:1514 (#5–#623).
Hjälper med: U8.1, U8.2 och U8.4.

2. `tcp.port==22`
Hittar: all SSH-trafik på port 22, åt båda hållen.
I min fångst: 23 träffar i tre konversationer:
- 172.20.1.108:44000 → min server:22, 3 paket (#462–#464), skannern hittar öppen port 22
- 172.20.1.108:52984 → min server:22, 10 paket, 5 382 byte, 16,0 s (#543–#600), den lyckade inloggningen
- min server:45098 → 172.20.1.112:22, 10 paket, 4 382 byte, 0,2 s (#552–#561), lateral rörelse
Hjälper med: U8.2 och U8.3, hitta inloggningen och den laterala SSH-anslutningen. Inga upprepade korta sessioner, alltså ingen brute force.

3. `tcp.flags.reset==1 && tcp.srcport==1514`
Hittar: RST från port 1514, alltså "ingen lyssnar här".
I min fångst: 38 RST från 172.20.1.58:1514 (#6–#624). SYN-försöken mot 1514 kommer med exakt 5,0 s mellanrum under hela fångsten.
Hjälper med: U8.4, skilja den trasiga loggklienten (ett mål, en port, jämn takt) från skanningen.

4. `dns.flags.response==0 && dns.qry.name.len > 25`
Hittar: DNS-frågor med långa namn. Jag kollade först vilka längder som finns: 4 frågor är 20 tecken, 1 är 31 och 13 är 32. Tröskeln 25 skiljer dem åt.
I min fångst: 14 frågor (#564–#596), alla mot `*.sync.telemetri-app.net`. De vanliga frågorna (`ctf.sec.chas-lab.dev` och `log.sec.chas-lab.dev`, #1, #3, #576, #582) faller bort.
Hjälper med: U8.1, hitta DNS-tunneln.

5. `dns.qry.type == 16`
Hittar: TXT-frågor och svar, en ovanlig frågetyp.
I min fångst: 28 paket (#564–#597), 14 frågor och 14 svar, alla mot `sync.telemetri-app.net`.
Hjälper med: U8.1 och för att döma AI-förslaget om TXT-filtret.

Kontrollerat utan träff: `tcp.port==443` gav 0 paket, alltså ingen HTTPS-uppladdning. `tcp.analysis.flags` gav 0 paket, alltså inga återsändningar eller andra TCP-fel enligt Expert Info.
