# Playbook: Zonöverträdelse (T1046)

**Monitor:** `T1046 zonöverträdelse <server>` · loggprefix `ZON-IN-DROP` · index `wazuh-archives-*`
**Larmet betyder:** någon har försökt nå en port på servern som flödestabellen inte tillåter, och paketfiltret (nftables) har stoppat det. Det kan vara kartläggning inför ett angrepp (portskanning), ett flöde som saknas i regelverket eller ett eget test.
**När:** playbooken startar när monitorn larmar – börja då på steg 3. Steg 1–2 är förberedelse och görs i förväg, inte under larmet.

**Platshållare:** byt ut hela `<…>`, inklusive pilarna. `<server>` = servern i larmet (t.ex. `elev-38`), `<källan>` = adressen i `data.srcip` från steg 4.
**Notera** = skriv in i din post i `triagelogg.md` under Observation. Alla tider i UTC (Wazuh visar svensk tid, +1 h).

---

## 1. Förberedelse

1. **Kontrollera** i förväg, till exempel vid passets början, att monitorn är aktiv: index `wazuh-archives-*` (raderna finns inte i `wazuh-alerts-*`, eftersom ingen standardregel larmar på dem), fönster 5 min, schema 1 min, filter `ZON-IN-DROP` och servernamnet.
2. **Ha** teamets testlogg och flödestabell öppna. I testloggen står planerade tester med tid, källa och mål. I flödestabellen står vilka flöden som ska släppas in.

## 2. Detektion och analys

3. **Notera** larmets tid och server i Alerting → Alerts.
4. **Sök** i Discover, `wazuh-archives-*`, tidsfönster ±5 min runt larmet:
   `location: *<server>* and data.action: ZON-IN-DROP`
   *Inga träffar?* Pröva `full_log: "<server>" and full_log: "ZON-IN-DROP"`. Sökningen på location har ibland inte gett några träffar.
   Notera `data.srcip` – det är **<källan>**. Notera också `data.dstip`, `data.dstport`, `data.protocol` och nätkortet (`IN=` i `full_log`: `eth1` = labbnätet, `eth2` = teamnätet).
   Exempel på rad: `elev-38 kernel: ZON-IN-DROP IN=eth1 OUT= ... SRC=172.20.1.2 DST=172.20.1.138 ... PROTO=TCP ... DPT=80 ... SYN`
5. **Räkna** hur många olika portar `<källan>` har försökt nå. Klicka på `data.dstport` i fältlistan, så visas de vanligaste värdena.
   En eller två rader mot samma port är vanligt: TCP skickar om SYN när inget svar kommer.
   **Obs:** regeln loggar högst 10 rader per minut (`limit rate 10/minute` i `zon.nft`). En snabb skanning syns därför bara delvis, så verkligheten kan vara större än det du ser.
6. **Sök** utan värdfilter, samma tidsfönster:
   `data.action: ZON-IN-DROP and data.srcip: <källan>`
   Bara träffar från `<server>` = källan har inte provat mot fler servrar i teamet.
7. **Jämför** med flödestabellen: finns flödet `<källan>` → `<server>` på `data.dstport`?
   *Finns flödet i tabellen?* Då ska trafiken släppas in, och det är ett regelfel i `zon.nft` – gå till steg 10.
   Vanligt exempel: ctf-servern (`172.20.1.10`) gör kontroller mot nya portar. Vecka 7 är det tcp/80 (U7.2) och tcp/7500 + elevnumret (U7.3).
8. **Sök** om källan har nått servern på tillåtna portar. Paketfiltret loggar bara det som stoppas, så det som släpps igenom (t.ex. 22 eller 5432) syns inte här. Tidsfönster en timme före larmet fram till nu:
   `location: *<server>* and data.srcip: <källan>`
   Lyckad inloggning (5715) eller misslyckade inloggningar (5710/5712/5760/5763) från samma källa? Då hör larmet ihop med [brute-force.md](brute-force.md).
9. **Jämför** med testloggen: finns en anteckning med samma tid, källa, server och port?

### Beslutspunkt

| Avfärda om | Eskalera om |
|---|---|
| Steg 9 stämmer på tid, källa, server och port | Ingen anteckning i testloggen stämmer och källan är okänd |
| eller ett fåtal paket mot en enda port från en känd intern källa (jump, ctf-servern, teamets servrar) | eller många olika portar från samma källa (portskanning, steg 5) |
| och inga inloggningsförsök från källan (steg 8) | eller samma källa mot flera servrar (steg 6) |
| | eller källan har loggat in eller försökt logga in på en tillåten port (steg 8) |

Regelfel (steg 7) är varken avfärda eller eskalera: rätta regeln i steg 10 och notera det.

**Eskalera till:** teamet, och kursledaren om källan är okänd eller skannar flera servrar.
**Underlag:** tid, server, källa, portar, antal rader, vilka servrar som fick träffar och resultatet från steg 8.

## 3. Begränsning, utrotning och återställning

10. **Regelfel:** lägg till flödet i `zon.nft` och i flödestabellen, och ladda om regelverket. **Stäng inte av paketfiltret** för att få bort larmet.
11. **Kontrollera** att paketfiltret fortfarande är laddat:
    `sudo nft list ruleset | grep ZON-IN-DROP`
    Förväntat: minst en rad med `log prefix "ZON-IN-DROP "`.
12. **Kontrollera** att källan inte har en öppen anslutning till servern:
    `sudo ss -tnp | grep <källan>`
    Förväntat: ingen utskrift. Om det kommer en rad har källan en anslutning till en tillåten port, och då ska den följas upp i steg 8.
13. **Portskanning från en okänd extern källa:** blockera källan helt, även på de tillåtna portarna:
    `sudo nft insert rule inet zon in ip saddr <källan> drop`
    (körningsändring – lägg in raden i zon.nft om blockeringen ska vara kvar efter omstart)
    **Intern källa:** ta reda på vem som satt på maskinen innan du blockerar.
14. **Säkra** posterna från steg 4–8 (skärmdump eller export).

## 4. Efterarbete

15. **Dokumentera** i `triagelogg.md`: observation, vad hände, vad berördes, vad ska göras och skäl.
16. **Stäng** ärendet och skriv in i playbooken om något steg saknades eller var otydligt.

---

**Ej korstestad ännu.** Skriven av Naima (elev-38) 2026-11-16 utifrån detektionerna för elev-38, elev-09 och elev-46.
