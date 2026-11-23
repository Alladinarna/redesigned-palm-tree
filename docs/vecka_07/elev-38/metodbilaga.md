# Metodbilaga – elev-38

Prompten och AI:ns svar ligger i kodrutor så att texten visas exakt som den skickades och kom tillbaka, utan ändringar.

## 1. Underlag som matades in

- Härdningslistan (hardningslista.md), utan inledningen med serverns adresser
- Utdata från `sudo /usr/local/bin/verifiera-hardning` efter omstart
- Utdata från `ps -eZ | grep zonvakt`

Maskerade värden: ctf-serverns adress är utbytt mot `CTF-SERVER`. Serverns egna adresser (labbnätet och teamnätet) är borttagna. Inga lösenord, nycklar, tokens eller flaggor fanns med.

## 2. Prompt, ordagrant

En AI-assistent (i en annan chatt, där jag hade gjort härdningen) satte ihop prompten utifrån min härdningslista och veckoguidens krav: bara underlaget, numrerade påståenden, markera det som saknas, luckor sist. Jag skickade den utan ändringar i en **ny chatt** 2026-11-23, så att utkastet bara bygger på underlaget.

````
Skriv ett utkast till en härdningsrapport för min server. Den kör Rocky Linux 9 med SELinux targeted och är databasservern i ett team på fyra.

Regler:
- Håll dig bara till underlaget nedan.
- Skriv rapporten som numrerade påståenden (P1, P2 …), ett per rad, och ange efter varje vilken del av underlaget det bygger på.
- Markera tydligt det som inte finns i underlaget.
- Lista luckor i underlaget sist.

Underlag 1 – härdningslista:

| Nr | Åtgärd | Motivering | Förväntad effekt | Hur den verifierades | Skript? |
|---|---|---|---|---|---|
| 1 | SELinux i Enforcing, nu och efter omstart | Utan MAC skyddar bara filrättigheterna (DAC), och dem går root förbi. setenforce försvinner vid omstart | Policyn tvingas alltid, inte bara loggas | getenforce: Enforcing. grep ^SELINUX= /etc/selinux/config: SELINUX=enforcing. Samma efter omstart | Ja |
| 2 | Tjänsten zonvakt (port 7538) under egen tvingande policy, domänen zonvakt_t | zonvakt kör som root. I unconfined_service_t kunde den skriva /etc/zonvakt-otillaten | hej fungerar, overtrad nekas trots root | ps -eZ: zonvakt_t. semanage permissive -l: tom. overtrad: "nekad: Permission denied". AVC denied { write } på etc_t, permissive=0. Samma rad i Wazuh (rule.id 100200) | Ja |
| 3 | Bestående filkontext httpd_sys_content_t för /srv/zonwebb (semanage fcontext + restorecon, inte chcon) | httpd gav 403. AVC: httpd_t nekades getattr på var_t. chcon försvinner vid relabel | httpd får läsa katalogen, tål relabel | semanage fcontext -l -C visar regeln. ls -Zd: httpd_sys_content_t. curl gav kvittot | Ja |
| 4 | Paketfiltret behåller policy drop. Bara två nya flöden från CTF-SERVER (tcp/80, tcp/7538) släpps in, före loggregeln ZON-IN-DROP | Kontrollerna kräver flödena. Att stänga av filtret hade öppnat allt | Bara CTF-SERVER når portarna, allt annat nekas och loggas | nft list chain inet zon in visar reglerna och policy drop. systemctl is-enabled nftables: enabled | Ja |

Underlag 2 – utdata från sudo /usr/local/bin/verifiera-hardning efter omstart:

GÄLLER: SELinux i Enforcing nu
GÄLLER: SELinux enforcing efter omstart
GÄLLER: policymodulen zonvakt är laddad
GÄLLER: zonvakt kör i domänen zonvakt_t
GÄLLER: zonvakt_t är inte permissiv
GÄLLER: bestående fcontext-regel för /srv/zonwebb
GÄLLER: /srv/zonwebb har typen httpd_sys_content_t
GÄLLER: paketfiltret in har policy drop
GÄLLER: nftables startar vid omstart
felkod: 0

Underlag 3 – ps -eZ | grep zonvakt:

system_u:system_r:zonvakt_t:s0    26385 ?        00:00:00 zonvakt
````

## 3. Råsvar, oredigerat

````
# Härdningsrapport (utkast): databasservern

**Källor:**
- **U1** = härdningslistan (nr 1–4)
- **U2** = utdata från `verifiera-hardning` efter omstart
- **U3** = `ps -eZ | grep zonvakt`

**Så här läser du markeringarna:**
- ⚠️ **SAKNAS I UNDERLAGET** betyder att påståendet inte kan kontrolleras med det underlag som finns.
- *Avsikt* betyder att det bara står i U1:s kolumner Motivering eller Förväntad effekt. Det är alltså inte visat.

---

### Om servern
**P1** Servern kör Rocky Linux 9 med SELinux i läget targeted och är databasservern i ett team på fyra. *Källa: din beskrivning.* ⚠️ **SAKNAS I UNDERLAGET.** Ingen utdata visar OS-version, policytyp eller databas.

### Åtgärd 1: SELinux i Enforcing
**P2** SELinux står i Enforcing just nu. *Källa: U1 nr 1 (getenforce), U2 rad 1*
**P3** `/etc/selinux/config` innehåller `SELINUX=enforcing`. *Källa: U1 nr 1*
**P4** Enforcing gäller även efter omstart. *Källa: U1 nr 1 ("Samma efter omstart"), U2 rad 2*
**P5** Varför: utan MAC skyddar bara filrättigheterna (DAC), och dem går root förbi. Dessutom försvinner `setenforce` vid omstart. *Källa: U1 nr 1, Motivering*

### Åtgärd 2: zonvakt under egen policy
**P6** Före åtgärden körde zonvakt i `unconfined_service_t` och kunde skriva `/etc/zonvakt-otillaten`. *Källa: U1 nr 2, Motivering.* ⚠️ **SAKNAS I UNDERLAGET:** det finns ingen utdata som visar läget före.
**P7** Policymodulen zonvakt är laddad. *Källa: U2 rad 3*
**P8** zonvakt kör i domänen `zonvakt_t` (PID 26385, kontext `system_u:system_r:zonvakt_t:s0`). *Källa: U1 nr 2, U2 rad 4, U3*
**P9** `zonvakt_t` är inte permissiv, eftersom `semanage permissive -l` är tom. *Källa: U1 nr 2, U2 rad 5*
**P10** zonvakt kör som root. *Källa: U1 nr 2, Motivering.* ⚠️ **SAKNAS I UNDERLAGET:** U3 visar SELinux-kontexten men inte Linux-användaren.
**P11** zonvakt använder port 7538. *Källa: U1 nr 2.* ⚠️ **SAKNAS I UNDERLAGET:** ingen utdata visar att tjänsten lyssnar på porten.
**P12** Testet overtrad nekades med "nekad: Permission denied". *Källa: U1 nr 2, Verifiering*
**P13** Nekandet loggades som AVC `denied { write }` på `etc_t` med `permissive=0`. *Källa: U1 nr 2, Verifiering*
**P14** Samma AVC-rad syns i Wazuh med rule.id 100200. *Källa: U1 nr 2, Verifiering*
**P15** hej fungerar. *Källa: U1 nr 2, Förväntad effekt (Avsikt).* ⚠️ **SAKNAS I UNDERLAGET:** det finns ingen verifiering av hej.

### Åtgärd 3: bestående filkontext för /srv/zonwebb
**P16** Före åtgärden gav httpd 403, och en AVC visade att `httpd_t` nekades `getattr` på `var_t`. *Källa: U1 nr 3, Motivering.* ⚠️ **SAKNAS I UNDERLAGET:** det finns ingen utdata som visar läget före.
**P17** Kontexten sattes med `semanage fcontext` och `restorecon`, inte med `chcon`. *Källa: U1 nr 3*
**P18** En bestående fcontext-regel för `/srv/zonwebb` finns (`semanage fcontext -l -C`). *Källa: U1 nr 3, U2 rad 6*
**P19** `/srv/zonwebb` har typen `httpd_sys_content_t` (`ls -Zd`). *Källa: U1 nr 3, U2 rad 7*
**P20** httpd kan läsa katalogen: "curl gav kvittot". *Källa: U1 nr 3.* ⚠️ **SAKNAS I UNDERLAGET:** curl-utdatan finns inte med, och det framgår inte vilket kvitto det var.
**P21** Märkningen tål en relabel. *Källa: U1 nr 3, Förväntad effekt (Avsikt).* ⚠️ **SAKNAS I UNDERLAGET:** ingen relabel har körts. Underlaget visar bara att regeln finns.

### Åtgärd 4: paketfiltret
**P22** Kedjan `in` i tabellen `inet zon` har policy drop. *Källa: U1 nr 4, U2 rad 8*
**P23** nftables startar vid omstart (`systemctl is-enabled nftables`: enabled). *Källa: U1 nr 4, U2 rad 9*
**P24** Två nya flöden från CTF-SERVER släpps in: tcp/80 och tcp/7538. *Källa: U1 nr 4.* ⚠️ **SAKNAS I UNDERLAGET:** själva utdatan från `nft list chain` finns inte med, och CTF-SERVERs adress står inte.
**P25** De två reglerna ligger före loggregeln ZON-IN-DROP. *Källa: U1 nr 4.* ⚠️ **SAKNAS I UNDERLAGET:** ordningen syns inte i U2.
**P26** Bara CTF-SERVER når portarna, och allt annat nekas och loggas. *Källa: U1 nr 4, Förväntad effekt (Avsikt).* ⚠️ **SAKNAS I UNDERLAGET:** inget test från en annan värd och ingen loggrad.

### Samlad kontroll
**P27** `sudo /usr/local/bin/verifiera-hardning` kördes efter omstart. Alla nio kontroller gav GÄLLER, och skriptet skrev `felkod: 0`. *Källa: U2*
**P28** Alla fyra åtgärder är markerade "Skript? Ja". *Källa: U1.* ⚠️ **SAKNAS I UNDERLAGET:** det framgår inte vad "Ja" betyder eller vilket skript som avses.

---

### Luckor i underlaget
1. **Databasen saknas helt.** Inget i underlaget handlar om databastjänsten: inte dess port, SELinux-domän, användare eller brandväggsflöden för klienter. Underlaget beskriver bara zonvakt och httpd, så rapporten visar inte att servern är en databasserver.
2. **OS och policytyp är inte visade.** Ingen utdata visar Rocky Linux 9 eller att policyn är targeted. `getenforce` visar bara läget, inte policytypen.
3. **Skriptets innehåll saknas.** Det går inte att se vad varje GÄLLER-rad faktiskt kontrollerar.
4. **Uppgifter om körningen saknas.** Datum, tid, värdnamn och vem som körde finns inte med, varken för U2 eller U3. Det står inte heller om U3 togs före eller efter omstarten.
5. **Lägena före åtgärderna har ingen utdata:** `unconfined_service_t`, skrivningen till `/etc`, 403 och AVC på `var_t`.
6. **zonvakt är inte fullt verifierad:** körning som root, port 7538 och hej.
7. **httpd är inte fullt verifierad:** curl-utdatan saknas och inget relabel-test har gjorts.
8. **Paketfiltret är inte fullt verifierat:**
   - nft-utdatan saknas.
   - CTF-SERVERs adress saknas.
   - Regelordningen syns inte.
   - Inget negativt test från en annan värd.
   - Ingen loggrad från ZON-IN-DROP.
9. **Skriptet täcker inte allt.** overtrad, AVC-raden, Wazuh, curl och de två nft-reglerna ingår inte i U2.
10. **Wazuh-konfigurationen och regel 100200 är inte beskrivna.**
11. **Teamets roller saknas.** Det framgår inte vem i teamet som gjorde vad eller vem som ansvarar för servern.

Vill du att jag lägger utkastet i ett dokument, så att teamet kan kommentera det?
````

## 4. Rättelselogg – en rad per ändrat påstående

Alla 28 påståenden är dömda i [hardningsrapport.md](hardningsrapport.md). Jag körde alla kommandon som avgjorde domarna på servern. AI-assistenten i härdningschatten hjälpte mig att skriva ihop domarna och beläggen utifrån mina utskrifter, och jag kontrollerade varje dom mot utskriften. Här är de som ändrades:

| Påst. nr | Påstående (kort) | Dom | Kommando som avgjorde | Faktiskt utfall | Feltyp | Ändrat till |
|---|---|---|---|---|---|---|
| P1 | "databasservern" | fel (delvis) | `sudo ss -tlnp \| grep 5432` | Ingen tjänst lyssnar på 5432 | Fel i eget underlag (min prompt). AI:n flaggade det själv som lucka 1 | elev-38 representerar Databaszonen. Ingen databastjänst körs ännu, men flödet F10 (5432) är förberett |
| P8 | PID 26385 | inaktuellt | `sudo ss -tlnp` | pid 986 efter omstarten | Inaktuellt – utdatan i underlag 3 togs före omstarten | zonvakt kör i `zonvakt_t` (PID anges inte) |
| P26 | "allt annat nekas och loggas" | fel | `sudo nft list chain inet zon in` | `limit rate 10/minute burst 5 packets log` | Fel i eget underlag (överdrift i härdningslistan) | Ny trafik in nekas (policy drop). Nekandena loggas, högst 10 rader per minut |
| P28 | "Skript? Ja" | stämmer (förtydligat) | `cat /usr/local/bin/verifiera-hardning` | Skriptet täcker inte overtrad, AVC-raden eller nft-reglerna | Ogrundat i underlaget – skriptet fanns inte med | "Ja" = verifieras med skriptet. För nr 2 och 4 verifieras resten manuellt |

**Iakttagelse:** AI-utkastet hittade inte på något. Alla tre fel kom från mitt eget underlag (prompten och härdningslistan) eller från att underlaget var gammalt (PID före omstarten). AI:n markerade dessutom själv de flesta svaga punkterna som "SAKNAS I UNDERLAGET". Det som gav domen var kommandona på servern, inte hur säkert texten lät.

## 5. Utelämningslista – vad som medvetet inte matades in, och varför

- **zon.nft:** innehåller adresserna till jump, ctf-servern, loggservern och Serverzonen. Tillsammans är det en karta över nätet. Reglerna som behövdes beskrivs i härdningslistan med `CTF-SERVER` i stället för adressen.
- **Serverns adresser (labbnätet och teamnätet) och värdnamnet i inledningen:** inte publika. Behövdes inte för utkastet.
- **zonvakt.te:** utelämnad för att hålla underlaget kort. Policyns innehåll granskades i stället direkt mot audit2allow under arbetet (se hardningslista.md, avsnittet Policyn för zonvakt).
- **AVC-rader och Wazuh-poster i rå form:** innehåller adresser och löpnummer från servern. Sammanfattade i härdningslistan.
- **Lösenord, tokens, SSH-nycklar och flaggor:** aldrig inmatade.

## Tillägg: där AI:n hade fel under själva härdningen

Under arbetet på elev-38 gav en AI-assistent kommandon steg för steg. Jag körde varje kommando själv och jämförde med det förväntade svaret. Tre gånger hade AI:n fel:

| Vad AI:n sa | Vad som hände | Hur jag upptäckte det | Feltyp |
|---|---|---|---|
| `sudo verifiera-hardning` skulle köra skriptet | `sudo: verifiera-hardning: command not found` | Körde kommandot. sudo letar inte i /usr/local/bin på Rocky Linux 9 (secure_path). Rättat till `sudo /usr/local/bin/verifiera-hardning` | Ogrundat |
| Raderna från audit2allow räckte, och tjänsten skulle fungera när permissive togs bort | `echo hej` gav `Connection reset by peer`. Ingen ny AVC syntes | `journalctl -u zonvakt`: PermissionError på `sendall`. read/write på tcp_socket saknades – audit2allow hade inte föreslagit dem. Lade till dem, byggde om och testade | Ogrundat |
| `grep zon /etc/sysconfig/nftables.conf` utan sudo | `Permission denied` | Körde kommandot. Rättat med sudo | Ogrundat |

Lärdom: ett förslag som låter rätt är inte verifierat förrän kommandot har körts och svaret jämförts med det förväntade.
