# Playbook: Nytt användarkonto (T1136)
 
**Monitor:** `T1136 nytt konto <server>` · regel 5902 · index `wazuh-alerts-*`
**Larmet betyder:** någon har skapat ett konto med inloggningsbar shell på servern – kan vara en bakdörr för att komma tillbaka (persistence).
**När:** playbooken startar när monitorn larmar.
 
Byt `<server>` mot servern i larmet (t.ex. elev-46) och `<kontot>` mot kontonamnet. Alla tider i UTC.
 
---
 
## 1. Förberedelse
 
1. **Kontrollera** före passet att monitorn är aktiv: index `wazuh-alerts-*`, fönster 5 min, schema 1 min, filter `rule.id: 5902` och inte `data.shell: *nologin*`.
2. **Ha** teamets testlogg öppen – där står planerade tester med tid, server och kontonamn.
## 2. Detektion och analys
 
3. **Notera** larmets tid och server i Alerting → Alerts.
4. **Sök** i Discover, `wazuh-alerts-*`, ±5 min runt larmet:
   `location: *<server>* and rule.id: 5902`
   Notera `data.dstuser` (kontot), `data.uid`, `data.shell`, `data.home` och terminalen: den står som `from=` i slutet av texten i fältet `full_log` (hela loggraden).
5. **Sök** vem som skapade kontot, samma sekund:
   `location: *<server>* and rule.id: 5402`
   Välj posten där `data.command` innehåller `useradd` (det kan finnas fler, t.ex. `passwd <kontot>`). Notera `data.srcuser` (vem), `data.command` och `data.tty`.
   *Ingen 5402-post med useradd?* Kontot skapades utan sudo – gå direkt till eskalering.
6. **Sök** hur skaparen kom in, timmen före larmet:
   `location: *<server>* and data.dstuser: <användaren från steg 5> and rule.groups: sshd`
   Lyckad inloggning (5715) – från vilken `data.srcip`? Föregicks den av misslyckade inloggningar (5710/5712/5760/5763) från samma källa?
7. **Sök** om det nya kontot har använts, från larmet till nu:
   `location: *<server>* and data.dstuser: <kontot> and rule.id: 5715`
   Finns en inloggning är kontot inte bara skapat utan använt.
8. **Sök** utan värdfilter, senaste 24 h:
   `data.dstuser: <kontot>`
   Finns samma konto på fler servrar?
9. **Jämför** med testloggen: finns en anteckning med samma tid, server, användare och kontonamn?
### Beslutspunkt
 
| Avfärda om | Eskalera om |
|---|---|
| Steg 9 stämmer på tid, server, användare och kontonamn | Ingen anteckning i testloggen stämmer |
| och inga misslyckade inloggningar före (steg 6) | eller misslyckade inloggningar från samma källa före (steg 6) |
| | eller det nya kontot har loggat in utan att det står i testloggen (steg 7) |
| | eller uid 0, eller uid under 1000 med `/bin/bash` |
| | eller samma konto på flera servrar (steg 8) |
 
**Eskalera till:** teamet, och kursledaren om källan är jump eller okänd.
**Underlag:** tid, server, kontonamn, 5402-posten (vem och kommando), källadress för inloggningen, om kontot har använts och om det finns på fler servrar.
 
## 3. Begränsning, utrotning och återställning
 
10. **Lås** kontot direkt vid eskalering: `sudo usermod -L -e 1 <kontot>` (låser lösenordet och sätter kontot som utgånget, så att även SSH-nycklar stoppas) och avsluta dess sessioner: `sudo pkill -KILL -u <kontot>`. Går att ångra med `sudo usermod -U -e "" <kontot>`.
11. **Säkra** posterna från steg 4–8 (skärmdump eller export) innan något tas bort.
12. **Ta bort** kontot: `sudo userdel -r <kontot>`. Gäller även testkonton.
13. **Verifiera** att det är borta: `getent passwd <kontot>` ska inte ge något.
14. **Byt** lösenord eller nycklar för användaren i steg 5 om inloggningen inte går att förklara.
## 4. Efterarbete
 
15. **Dokumentera** i `triagelogg.md`: observation, slutsats, berört, beslut och skäl.
16. **Stäng** ärendet och skriv in i playbooken om något steg saknades eller var otydligt.
