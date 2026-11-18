# Playbook: Root-kommando (T1548.003)

**Monitor:** `T1548.003 root-kommando <server>` · nyckel `root-cmd` **eller** `rootcmd` · index `wazuh-archives-*`
*(exakt monitornamn varierar per person – elev-24: "T1548.003 kommando som root via sudo elev-24 – auditd rootcmd", elev-38: "T1548.003 root-kommando på elev-38". T1548.003 = Sudo and Sudo Caching.)*
**Larmet betyder:** någon körde ett kommando med root-rättigheter (typiskt via sudo) på servern. auditd loggar det och skickar det vidare via `audisp-syslog`. Det kan vara egen administration – men också en angripare som redan är inne och agerar som root.
**När:** playbooken startar när monitorn larmar – börja då på steg 3. Steg 1–2 är förberedelse och görs i förväg, inte under larmet.

**Platshållare:** byt ut hela `<…>`, inklusive pilarna. `<server>` = servern i larmet (t.ex. `elev-24`), `<auid>` = inloggnings-id från steg 4 (`1000` = `student`), `<kontot>`/`<personen>` = kontot/personen bakom `<auid>` från steg 5, `<källan>` = inloggningens `data.srcip` från steg 6.
**Notera** = skriv in i din post i `triagelogg.md` under Observation. Alla tider i UTC (Wazuh visar svensk tid, +1 h).

> **Det här är den brusigaste av de fyra monitorerna** (elev-24:s detektioner: "högst falsklarmsrisk av de fyra"). I elev-24:s verifierade fönster var det 883 träffar på 505 h (≈ 1,7/h) och **allt var egen administration som `student`** – t.ex. nft, ss, journalctl och SELinux-arbetet i vecka 7 (323 träffar den 17/11). Jobbet här är alltså att snabbt skilja *eget arbete* från *root som någon annan tagit sig till*. Avgörandet ligger inte i att kommandot kördes som root, utan i **vem** som körde det, **varifrån sessionen kom** och **vad** kommandot gjorde.

---

## 1. Förberedelse

1. **Kontrollera** i förväg, till exempel vid passets början, att monitorn är aktiv: index `wazuh-archives-*` (raderna finns inte i `wazuh-alerts-*`, eftersom ingen standardregel larmar på root-kommandon), fönster 5 min, schema 1 min, filter `full_log: "type=SYSCALL"` och `full_log: "success=yes"` och nyckeln, avgränsat på servern.
   > **Nyckeln bytte namn:** auditregeln använde `root-cmd` t.o.m. 7/11 05:16 UTC och `rootcmd` efter det (bytet skedde när auditreglerna laddades om). Monitorn söker på `rootcmd`; **vid sökning bakåt i tiden, ta med båda** – annars missas allt före 7/11.
2. **Ha** teamets testlogg öppen – där står planerade tester med tid, server, person och kommando. Ha också en bild av normalbilden: vem som brukar jobba på servern och vilka root-kommandon som är rutin (nft, ss, journalctl, systemctl, semanage/restorecon, dnf, verifieringsskripten).

## 2. Detektion och analys

3. **Notera** larmets tid och server i Alerting → Alerts.
4. **Sök** i Discover, `wazuh-archives-*`, tidsfönster ±5 min runt larmet:
   `location: *<server>* and full_log: "type=SYSCALL" and full_log: "success=yes" and (full_log: "root-cmd" or full_log: "rootcmd")`
   *Inga träffar?* Pröva `full_log: "<server>" and full_log: "type=SYSCALL" and full_log: "success=yes" and (full_log: "root-cmd" or full_log: "rootcmd")`. Sökningen på `location` har ibland inte gett några träffar.
   Allt ligger i `full_log` (Wazuh tolkar inte auditposterna). Notera ur raden:
   - `auid=` – **inloggnings-id**, vem som ursprungligen loggade in (`1000` = `student`). Detta är **<auid>** och är det viktigaste fältet. `auid=4294967295` (visas som `unset`/`-1`) betyder att ingen inloggad person initierade kommandot – t.ex. ett system-/cron-jobb (se gränsfall).
   - `uid=0`/`euid=0` – kördes som root.
   - `syscall=59` – `execve`, dvs. ett program startades.
   - `exe=` – vilket program (t.ex. `/usr/bin/sudo`, `/usr/sbin/nft`).
   - `comm=`, `tty=`, `ses=` – programnamn, terminal och sessions-id. Notera `ses=` – det knyter ihop alla kommandon i samma session.
   - serienumret i `msg=audit(TID:SERIENUMMER)`.
   **Räkna bara `type=SYSCALL`.** Ett kommando ger flera auditposter (SYSCALL, EXECVE, PROCTITLE …), men nyckeln står bara i SYSCALL, så en SYSCALL = ett kommando.
5. **Se hela kommandoraden.** SYSCALL visar bara `exe=`. Själva argumenten (`a0 a1 a2 …`) står i **EXECVE-posten med samma serienummer**. Sök `full_log: "<SERIENUMMER>"` och läs EXECVE-raden, eller på servern:
   `sudo ausearch -i -k rootcmd -k root-cmd --start recent` (lägg till `-p <pid>` eller filtrera på serienumret). `ausearch -i` tolkar posten och visar `AUID=`, `UID=` och hela kommandot i klartext.
   Notera **<kontot>**/**<personen>** bakom `<auid>` och exakt vilket kommando som kördes.
6. **Ändra tidsfönstret** till en timme före larmet fram till larmet. **Sök** hur personen kom in på servern:
   `location: *<server>* and data.dstuser: <kontot> and rule.groups: sshd`
   Exempel ifyllt: `location: *elev-24* and data.dstuser: student and rule.groups: sshd`
   Lyckad inloggning (5715) – från vilken `data.srcip` (**<källan>**)? Föregicks den av misslyckade inloggningar (5710/5712/5760/5763) från samma källa? Då hör larmet ihop med [brute-force.md](brute-force.md).
7. **Kontrollera** om root-åtkomsten hör ihop med andra larm i samma fönster – ett root-kommando efter ett intrång är allvarligare än ett ensamt:
   - Nytt konto strax före/efter (rule.id 5902)? → [nytt-konto.md](nytt-konto.md). `useradd` syns dessutom som root-kommando här.
   - Zonöverträdelse från samma källa (`ZON-IN-DROP`)? → [zonovertradelse.md](zonovertradelse.md).
8. **Sök** om samma inloggnings-id kört root-kommandon på fler servrar, utan värdfilter, samma fönster:
   `full_log: "auid=<auid>" and full_log: "type=SYSCALL" and (full_log: "root-cmd" or full_log: "rootcmd")`
   Bara träffar från `<server>` = aktiviteten är inte spridd i teamet.
9. **Jämför** med testloggen: finns en anteckning med samma tid, server, person och kommando?
10. **Bedöm kommandot.** Är det rutinadministration (nft, ss, journalctl, systemctl, SELinux-verktyg, dnf, verifieringsskripten) eller ett **högriskkommando**? Högrisk = något som skapar beständighet eller försvagar skyddet:
    - konto/behörighet: `useradd`, `usermod`, `passwd`, `visudo`, skrivning i `/etc/sudoers*`, nya SSH-nycklar i någons `authorized_keys`
    - autentisering: ändringar i PAM (`/etc/pam.d/*`)
    - logg/spår: `systemctl stop|disable rsyslog|auditd`, `auditctl -D`, redigering av auditreglerna, tömning av `/var/log`, rensad kommandohistorik
    - hemligheter: läsning av `/etc/shadow`, privata nycklar
    - nät: `nft flush`, regler som öppnar brandväggen
    - beständighet: nya cron-jobb, nya systemd-enheter

### Beslutspunkt

| Avfärda om | Eskalera om |
|---|---|
| `<auid>` hör till en känd person på servern (normalt `student`) | `<auid>` hör inte till någon känd person, eller `auid` saknas (`unset`) för ett interaktivt kommando |
| och inloggningen i steg 6 är en känd, förklarad session (ingen föregående brute force) | eller root-åtkomsten nåddes via brute force (steg 6), nytt konto eller zonöverträdelse (steg 7) |
| och kommandot är rutinadministration (steg 10) | eller kommandot är ett högriskkommando (steg 10) |
| och raden stämmer mot testloggen, eller är tydlig rutin under ett eget arbetspass | eller samma `<auid>` kör root-kommandon på flera servrar (steg 8) utan att det står i testloggen |

**Eskalera till:** teamet, och kursledaren om inloggningen kom från jump eller en okänd källa.
**Underlag:** tid, server, `<auid>` och personen bakom, exakt kommando (EXECVE), `ses=`, hur sessionen kom in (steg 6), eventuella kopplade larm (steg 7) och om aktiviteten finns på fler servrar (steg 8).

## 3. Begränsning, utrotning och återställning

11. **Säkra** auditposterna först (skärmdump eller export av SYSCALL + EXECVE med serienumret) **innan** något ändras. `sudo ausearch -i -k rootcmd -k root-cmd` ger en läsbar kopia.
12. **Stoppa sessionen** om den är skarp och fortfarande aktiv: lås kontot bakom `<auid>` – `sudo usermod -L <kontot>` – och avsluta dess sessioner – `sudo pkill -KILL -u <kontot>` (eller stäng angriparens enskilda session: `sudo loginctl list-sessions` visar aktiva sessioner, `sudo loginctl terminate-session <id>` stänger en). Går att ångra med `sudo usermod -U <kontot>`.
    > Är `<auid>` ditt eget arbetskonto (`student`) och larmet skarpt därför att **kontot kapats**, byt lösenord och roter SSH-nycklar i stället för att låsa ut dig själv helt – men bryt angriparens session.
13. **Ångra kommandots effekt** efter vad steg 10 visade:
    - skapade ett konto → följ [nytt-konto.md](nytt-konto.md) (lås, säkra, `userdel -r`)
    - öppnade brandväggen eller flushade regler → återställ från `zon.nft` och ladda om
    - stoppade logg/audit → `sudo systemctl start rsyslog auditd` och verifiera att de skickar igen
    - la till nyckel/sudoers/cron/systemd-enhet → ta bort tillägget och kontrollera att inget mer lagts till i samma session (`ses=`)
14. **Verifiera** att spårningen fortfarande lever: auditregeln laddad med nyckeln – `sudo auditctl -l | grep -E 'root-cmd|rootcmd'` – och att `auditd` och `rsyslog` är `active` och levererar till log-servern.
15. **Byt** lösenord eller nycklar för personen bakom `<auid>` om inloggningen i steg 6 inte går att förklara.

## 4. Efterarbete

16. **Dokumentera** i `triagelogg.md`: observation, slutsats, vad som berördes, beslut och skäl.
17. **Var det eget test/rutin** (det vanliga), notera skälet och raden ur testloggen.
18. **Stäng** ärendet. Eftersom monitorn är brusig: fundera på om den bör snävas (t.ex. undanta kända rutinprogram eller bara larma på högriskkommandon i steg 10) och skriv in i playbooken om något steg saknades eller var otydligt.

### Gränsfall (larmar men är inte ett angrepp)
- **`CONFIG_CHANGE` med samma nyckel** när auditreglerna laddas om – det är ingen körning av ett kommando. Därför filtrerar vi på `type=SYSCALL`.
- **`success=no`** – t.ex. när skalet söker programmet i PATH (`exit=-2`) innan det hittas; ett kommando kan ge flera sådana. Räknas inte, vi filtrerar på `success=yes`.
- **`auid=unset` (`4294967295`)** – kommandot kom inte från en inloggad person utan från ett system-/cron-jobb. Oftast rutin, men värt en blick om kommandot är högrisk (steg 10).

---

**Ej korstestad ännu.** Skriven av elev-24 2026-11-18 utifrån root-kommando-detektionerna för elev-24, elev-38 och elev-46 (gemensamma fält: `type=SYSCALL`, `success=yes`, `auid`, nyckeln `root-cmd`/`rootcmd` i `wazuh-archives-*`).
