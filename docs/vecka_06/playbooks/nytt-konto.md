# Playbook: Nytt användarkonto (T1136)
 
**Monitor:** `T1136 nytt konto <server>` · regel 5902 · index `wazuh-alerts-*`
**Larmet betyder:** någon har skapat ett konto med inloggningsbar shell på servern – kan vara en bakdörr för att komma tillbaka (persistence).
**När:** playbooken startar när monitorn larmar – börja då på steg 3. Steg 1–2 är förberedelse och görs i förväg, inte under larmet.
 
**Platshållare:** byt ut hela `<…>`, inklusive pilarna. `<server>` = servern i larmet (t.ex. `elev-46`), `<kontot>` = det nya kontot från steg 4, `<skaparen>` = användaren från steg 5.
**Notera** = skriv in i din post i `triagelogg.md` under Observation. Alla tider i UTC.
 
---
 
## 1. Förberedelse
 
1. **Kontrollera** i förväg, till exempel vid passets början, att monitorn är aktiv: index `wazuh-alerts-*`, fönster 5 min, schema 1 min, filter `rule.id: 5902` och inte `data.shell: *nologin*`.
2. **Ha** teamets testlogg öppen – där står planerade tester med tid, server och kontonamn.
## 2. Detektion och analys
 
3. **Notera** larmets tid och server i Alerting → Alerts.
4. **Sök** i Discover, `wazuh-alerts-*`, tidsfönster ±5 min runt larmet:
   `location: *<server>* and rule.id: 5902`
   Notera `data.dstuser` – det är **<kontot>**, som används i steg 7–8. Notera också `data.uid`, `data.shell`, `data.home` och terminalen (`from=` i slutet av fältet `full_log`, hela loggraden).
5. **Sök** vem som skapade kontot, samma tidsfönster:
   `location: *<server>* and rule.id: 5402`
   Välj posten där `data.command` innehåller `useradd` (det kan finnas fler, t.ex. `passwd <kontot>`). Notera `data.srcuser` – det är **<skaparen>**. Notera också `data.command` och `data.tty`.
   *Ingen 5402-post med useradd?* Kontot skapades utan sudo – gå direkt till eskalering.
6. **Ändra tidsfönstret** till en timme före larmet fram till larmet. **Sök** hur skaparen kom in:
   `location: *<server>* and data.dstuser: <skaparen> and rule.groups: sshd`
   Exempel ifyllt: `location: *elev-46* and data.dstuser: student and rule.groups: sshd`
   Lyckad inloggning (5715) – från vilken `data.srcip`? Föregicks den av misslyckade inloggningar (5710/5712/5760/5763) från samma källa?
7. **Ändra tidsfönstret** från larmet fram till nu. **Sök** om det nya kontot har använts:
   `location: *<server>* and data.dstuser: <kontot> and rule.id: 5715`
   **Ingen träff är det vanliga** – kontot har inte använts. Träff = någon har loggat in med kontot.
8. **Ändra tidsfönstret** till senaste 24 h. **Sök** utan värdfilter:
   `data.dstuser: <kontot>`
   Bara träffar från `<server>` = kontot finns inte på fler servrar.
9. **Jämför** med testloggen: finns en anteckning med samma tid, server, skapare och kontonamn?
### Beslutspunkt
 
| Avfärda om | Eskalera om |
|---|---|
| Steg 9 stämmer på tid, server, skapare och kontonamn | Ingen anteckning i testloggen stämmer |
| och inga misslyckade inloggningar före (steg 6) | eller misslyckade inloggningar från samma källa före (steg 6) |
| | eller det nya kontot har loggat in utan att det står i testloggen (steg 7) |
| | eller uid 0, eller uid under 1000 med `/bin/bash` |
| | eller samma konto på flera servrar (steg 8) |
 
**Eskalera till:** teamet, och kursledaren om källan är jump eller okänd.
**Underlag:** tid, server, kontonamn, 5402-posten (vem och kommando), källadress för inloggningen, om kontot har använts och om det finns på fler servrar.
 
## 3. Begränsning, utrotning och återställning
 
10. **Lås** kontot direkt vid eskalering: `sudo usermod -L -e 1 <kontot>` (låser lösenordet och sätter kontot som utgånget, så att även SSH-nycklar stoppas) och avsluta dess sessioner: `sudo pkill -KILL -u <kontot>`. Går att ångra med `sudo usermod -U -e "" <kontot>`. **(verifierat 2026-11-12: inloggning med SSH-nyckel nekades efter låsning, upplåsning fungerade)**
11. **Säkra** posterna från steg 4–8 (skärmdump eller export) innan något tas bort.
12. **Ta bort** kontot: `sudo userdel -r <kontot>`. Gäller även testkonton.
13. **Verifiera** att det är borta: `getent passwd <kontot>` ska inte ge något.
14. **Byt** lösenord eller nycklar för skaparen om inloggningen i steg 6 inte går att förklara.
## 4. Efterarbete
 
15. **Dokumentera** i `triagelogg.md`: observation, slutsats, berört, beslut och skäl.
16. **Stäng** ärendet och skriv in i playbooken om något steg saknades eller var otydligt.
---
 
**Korstestad 2026-11-12 (Gabriel följde playbooken, Hugo antecknade).** Rättat efter korstestet: förberedelse vs larm förtydligat, platshållare och pilar förklarade, "notera" definierat, ifyllt exempel på sökning (steg 6), tidsfönster angivet i steg 4–8, kontonamnet i steg 7 kopplat till steg 4, förväntat resultat i steg 7–8.
