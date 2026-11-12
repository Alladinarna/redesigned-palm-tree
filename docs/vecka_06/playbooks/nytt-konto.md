# Playbook: Nytt användarkonto (T1136)
 
**Monitor:** `T1136 nytt konto elev-NN` · regel 5902 · index `wazuh-alerts-*`
**Larmet betyder:** någon har skapat ett konto med inloggningsbar shell på servern – kan vara en bakdörr för att komma tillbaka (persistence).
**När:** playbooken startar när monitorn larmar.
 
Byt `elev-NN` mot servern i larmet. Alla tider i UTC.
 
---
 
## 1. Förberedelse
 
1. **Kontrollera** före passet att monitorn är aktiv: index `wazuh-alerts-*`, fönster 5 min, schema 1 min, filter `rule.id: 5902` och inte `data.shell: *nologin*`.
2. **Ha** teamets testlogg öppen – där står planerade tester med tid, server och kontonamn.
## 2. Detektion och analys
 
3. **Notera** larmets tid och server i Alerting → Alerts.
4. **Sök** i Discover, `wazuh-alerts-*`, ±5 min runt larmet:
   `location: *elev-NN* and rule.id: 5902`
   Notera `data.dstuser` (kontot), `data.uid`, `data.shell`, `data.home` och `from=` i `full_log`.
5. **Sök** vem som skapade kontot, samma sekund:
   `location: *elev-NN* and rule.id: 5402`
   Notera `data.srcuser` (vem), `data.command` (kommandot) och `data.tty`.
   *Ingen 5402-post?* Kontot skapades utan sudo – gå direkt till eskalering.
6. **Sök** hur den användaren kom in, timmen före larmet:
   `location: *elev-NN* and rule.groups: sshd`
   Leta efter lyckad inloggning och källadress. Föregicks den av misslyckade inloggningar (5710/5712/5760/5763) från samma `data.srcip`?
7. **Sök** utan värdfilter, senaste 24 h:
   `data.dstuser: <kontot>`
   Finns samma konto på fler servrar?
8. **Jämför** med testloggen: finns en anteckning med samma tid, server, användare och kontonamn?
### Beslutspunkt
 
| Avfärda om | Eskalera om |
|---|---|
| Steg 8 stämmer på tid, server, användare och kontonamn | Ingen anteckning i testloggen stämmer |
| och inga misslyckade inloggningar före (steg 6) | eller misslyckade inloggningar från samma källa före (steg 6) |
| | eller uid 0, eller uid under 1000 med `/bin/bash` |
| | eller samma konto på flera servrar (steg 7) |
 
**Eskalera till:** teamet, kursledaren om källan är jump eller okänd.
**Underlag:** tid, server, kontonamn, 5402-posten (vem och kommando), källadress för inloggningen och om kontot finns på fler servrar.
 
## 3. Begränsning, utrotning och återställning
 
9. **Lås** kontot direkt vid eskalering: `sudo usermod -L -e 1 <kontot>` (låser lösenordet och sätter kontot som utgånget, så att även SSH-nycklar stoppas) och avsluta dess sessioner: `sudo pkill -KILL -u <kontot>`. Går att ångra med `sudo usermod -U -e "" <kontot>`. **(otestat)**
10. **Säkra** posterna från steg 4–7 (skärmdump eller export) innan något tas bort.
11. **Ta bort** kontot: `sudo userdel -r <kontot>`. Gäller även testkonton.
12. **Verifiera** att det är borta: `getent passwd <kontot>` ska inte ge något.
13. **Byt** lösenord eller nycklar för användaren i steg 5 om inloggningen inte går att förklara.
## 4. Efterarbete
 
14. **Dokumentera** i `triagelogg.md`: observation, slutsats, berört, beslut och skäl.
15. **Stäng** ärendet och skriv in i playbooken om något steg saknades eller var otydligt.
