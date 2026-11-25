# Metodbilaga – elev-24

Prompten och AI:ns svar ligger i kodrutor så att texten visas exakt som den skickades och kom tillbaka, utan ändringar.

## 1. Underlag som matades in

- Härdningslistan ([Härdningslista.md](Härdningslista.md)): tabellen och stycket om policyn, utan styckena om skriptet och httpd
- Utdata från `/usr/local/bin/verifiera-hardning; echo "felkod: $?"`, körd 2026-11-25
- Utdata från `ps -eo user,label,pid,comm | grep zonvakt`, körd 2026-11-25

Maskerade värden: ctf-serverns adress i härdningslistans rad 4 är utbytt mot `CTF-SERVER`. Inga lösenord, nycklar, tokens eller flaggor fanns med. `127.0.0.1` (loopback) och port 7524 lämnades kvar – de är inte känsliga.

## 2. Prompt, ordagrant

En AI-assistent (Claude Code, som jag använder i kursarbetet) satte ihop prompten utifrån min härdningslista och veckoguidens krav: bara underlaget, numrerade påståenden, markera det som saknas, luckor sist. Prompten skickades 2026-11-25 till en **ny AI-instans utan tidigare samtal**, så att utkastet bara bygger på underlaget.

````
Skriv ett utkast till en härdningsrapport för min server. Den kör Rocky Linux 9 med SELinux targeted.

Regler:
- Håll dig bara till underlaget nedan.
- Skriv rapporten som numrerade påståenden (P1, P2 …), ett per rad, och ange efter varje vilken del av underlaget det bygger på.
- Markera tydligt det som inte finns i underlaget.
- Lista luckor i underlaget sist.

Underlag 1 – härdningslista:

| Nr | Åtgärd | Motivering – varför just här | Förväntad effekt | Hur den verifieras | Skript? |
|---|---|---|---|---|---|
| 1 | SELinux enforcing nu och efter omstart | Tar en angripare över en tjänst kan den bara göra det dess domän tillåter, även om den kör som root. Utan enforcing gäller bara DAC och den går root förbi | Otillåtna åtgärder nekas och loggas som AVC | getenforce ska ge Enforcing och grep ^SELINUX= /etc/selinux/config ska ge SELINUX=enforcing | Ja |
| 2 | Egen tjänst (zonvakt) under egen tvingande SELinux-policy, domänen zonvakt_t | ps -eZ visade att zonvakt körde som root i unconfined_service_t, och echo overtrad \| nc 127.0.0.1 7524 lyckades skriva /etc/zonvakt-otillaten. Varken DAC eller MAC stoppade den | Tjänsten kan bara göra det policyn tillåter. Den kan inte längre skriva i /etc, men svarar fortfarande på vanliga anslutningar | ps -eZ ska visa zonvakt_t, seinfo --permissive ska inte lista zonvakt_t, echo hej ska ge "ok" och echo overtrad ska ge "nekad: Permission denied" | Ja (utom hej/overtrad-testet, som skriver en rad i tjänstens logg) |
| 3 | Webbkatalogen /srv/zonwebb märkt httpd_sys_content_t med semanage fcontext + restorecon (inte chcon) | curl gav 403 trots rättigheterna 644. AVC:n visade att httpd_t nekades getattr på en fil med typen var_t | httpd kan läsa katalogen i enforcing, och märkningen ligger kvar efter en relabel | ls -Z och matchpathcon på /srv/zonwebb/kvitto.txt ska båda ge httpd_sys_content_t, och curl http://127.0.0.1/zon/kvitto.txt ska ge 200 | Ja |
| 4 | Paketfiltret släpper bara in de flöden som står i flödestabellen (default deny). ctf till tcp/80 och tcp/7524 lades till som D8 och D9 | Kärnloggen visade ZON-IN-DROP från CTF-SERVER till DPT=80 och DPT=7524. Kedjan in har policy drop, så varje nytt flöde måste läggas till uttryckligen i stället för att brandväggen stängs av | Bara de flöden som står i tabellen kommer in, och allt annat droppas och loggas | grep -n "dport" /etc/nftables/zon.nft ska visa D8 och D9, och sudo nft list chain inet zon in ska visa samma regler i den aktiva brandväggen | Nej – nft list kräver root och skriptet ska gå att köra utan sudo. Kontrolleras därför manuellt |

Policyanteckning: Utgångspunkten var sepolicy generate --init. Från audit2allow -R togs files_manage_etc_files och auth_etc_filetrans_shadow bort (det är själva överträdelsen) och corecmd_exec_bin (den överlappar corecmd_mmap_bin_files och är bredare). read och write på tcp_socket lades till för hand: tjänsten kraschade i enforcing när den skulle svara, och nekandet syntes inte i audit-loggen eftersom systempolicyn har dontaudit domain domain:tcp_socket { read write }. corenet_tcp_bind_generic_port är fortfarande för bred (vilken oreserverad port som helst).

Underlag 2 – utdata från /usr/local/bin/verifiera-hardning; echo "felkod: $?":

GÄLLER SELinux är Enforcing nu (getenforce)
GÄLLER SELinux är enforcing efter omstart (/etc/selinux/config)
GÄLLER zonvakt kör i egen domän zonvakt_t
GÄLLER zonvakt_t är inte permissiv
GÄLLER /srv/zonwebb har httpd_sys_content_t som tål relabel
felkod: 0

Underlag 3 – ps -eo user,label,pid,comm | grep zonvakt:

root     system_u:system_r:zonvakt_t:s0      995 zonvakt
````

## 3. Råsvar, oredigerat

````
Utkast till härdningsrapport för servern (Rocky Linux 9, SELinux targeted)

Teckenförklaring:
- [VERIFIERAT] betyder att påståendet stöds av utdata i underlag 2 eller 3.
- [PLANERAT/FÖRVÄNTAT] betyder att påståendet bara står i härdningslistan (underlag 1) och inte har bekräftats med utdata.
- [EJ I UNDERLAGET] betyder att uppgiften inte finns i något underlag.

Systemet
- P1. Servern kör Rocky Linux 9 med SELinux targeted. [EJ I UNDERLAGET] Uppgiften kommer från din beskrivning, inte från någon utdata. (Källa: din beskrivning)

Åtgärd 1: SELinux enforcing
- P2. SELinux är Enforcing i den körande kärnan. [VERIFIERAT] (Källa: underlag 2, rad 1 "GÄLLER SELinux är Enforcing nu (getenforce)")
- P3. SELinux är satt till enforcing efter omstart i /etc/selinux/config. [VERIFIERAT] (Källa: underlag 2, rad 2)
- P4. Att systemet faktiskt startar i enforcing har inte prövats med en omstart. Bara konfigurationsfilen är kontrollerad. [EJ I UNDERLAGET] (Källa: underlag 1, åtgärd 1, verifieringskolumnen och underlag 2, rad 2)
- P5. Syftet är att en tjänst som tas över bara kan göra det dess domän tillåter, även om den kör som root. Otillåtna åtgärder ska nekas och loggas som AVC. [PLANERAT/FÖRVÄNTAT] (Källa: underlag 1, åtgärd 1, motivering och förväntad effekt)

Åtgärd 2: zonvakt i egen domän
- P6. Före åtgärden körde zonvakt som root i unconfined_service_t. Kommandot echo overtrad | nc 127.0.0.1 7524 kunde då skriva /etc/zonvakt-otillaten. [PLANERAT/FÖRVÄNTAT] Detta är en historisk iakttagelse som bara finns i listan, utan bifogad utdata. (Källa: underlag 1, åtgärd 2, motivering)
- P7. zonvakt kör nu i domänen zonvakt_t (PID 995, kontext system_u:system_r:zonvakt_t:s0). [VERIFIERAT] (Källa: underlag 2, rad 3 och underlag 3)
- P8. zonvakt kör fortfarande som användaren root. Begränsningen ligger alltså helt på MAC (SELinux), inte på DAC. [VERIFIERAT] (Källa: underlag 3, kolumnen user)
- P9. zonvakt_t är inte permissiv. [VERIFIERAT] (Källa: underlag 2, rad 4)
- P10. Att tjänsten svarar "ok" på hej och "nekad: Permission denied" på overtrad är [EJ VERIFIERAT – utdata saknas]. Testet ingår uttryckligen inte i skriptet. (Källa: underlag 1, åtgärd 2, kolumnen Skript?, och underlag 2, där testet saknas)
- P11. Policyn utgår från sepolicy generate --init. (Källa: policyanteckningen)
- P12. Tre regler från audit2allow -R togs bort: files_manage_etc_files och auth_etc_filetrans_shadow, eftersom de är själva överträdelsen, och corecmd_exec_bin, eftersom den är bredare än corecmd_mmap_bin_files och överlappar den. (Källa: policyanteckningen)
- P13. read och write på tcp_socket lades till för hand. Tjänsten kraschade i enforcing, och nekandet syntes inte i audit-loggen på grund av dontaudit domain domain:tcp_socket { read write } i systempolicyn. (Källa: policyanteckningen)
- P14. Kvarstående risk: corenet_tcp_bind_generic_port är för bred, eftersom den tillåter bind till vilken oreserverad port som helst. (Källa: policyanteckningen)
- P15. Kvarstående risk: Eftersom dontaudit-regler döljer vissa nekanden visar inte audit-loggen allt som nekas. (Källa: policyanteckningen, slutsats dragen ur P13)

Åtgärd 3: märkning av /srv/zonwebb
- P16. Före åtgärden gav curl 403 trots filrättigheterna 644. AVC:n visade att httpd_t nekades getattr på en fil av typen var_t. [PLANERAT/FÖRVÄNTAT] Detta är en historisk iakttagelse utan bifogad utdata. (Källa: underlag 1, åtgärd 3, motivering)
- P17. Märkningen görs med semanage fcontext och restorecon, inte med chcon. (Källa: underlag 1, åtgärd 3)
- P18. /srv/zonwebb har httpd_sys_content_t på ett sätt som tål relabel. [VERIFIERAT] Underlaget visar inte exakt vad skriptet kontrollerar. Listan anger ls -Z och matchpathcon på kvitto.txt. (Källa: underlag 2, rad 5 och underlag 1, åtgärd 3)
- P19. Att curl http://127.0.0.1/zon/kvitto.txt ger 200 är [EJ VERIFIERAT – utdata saknas]. (Källa: underlag 1, åtgärd 3, verifieringskolumnen. Raden finns inte i underlag 2)

Åtgärd 4: paketfilter
- P20. Kedjan in har policy drop (default deny). Varje nytt flöde ska läggas till uttryckligen. [PLANERAT/FÖRVÄNTAT] (Källa: underlag 1, åtgärd 4)
- P21. Kärnloggen visade ZON-IN-DROP från CTF-SERVER till DPT=80 och DPT=7524. Flöden från ctf till tcp/80 och tcp/7524 lades därför till som D8 och D9. [PLANERAT/FÖRVÄNTAT] Logg och regler finns inte bifogade. (Källa: underlag 1, åtgärd 4)
- P22. Att D8 och D9 finns i /etc/nftables/zon.nft och i den aktiva brandväggen är [EJ VERIFIERAT – utdata saknas]. Kontrollen är manuell, eftersom nft list kräver root och skriptet ska gå att köra utan sudo. (Källa: underlag 1, åtgärd 4, kolumnerna Hur den verifieras och Skript?)

Skriptresultat
- P23. Verifieringsskriptet avslutades med felkod 0, och alla fem kontroller rapporterade GÄLLER. (Källa: underlag 2)
- P24. Felkod 0 täcker bara de fem kontroller skriptet kör. Den säger ingenting om hej/overtrad-testet, curl-testet eller brandväggen. (Källa: underlag 1, kolumnen Skript?, jämfört med underlag 2)

---

Luckor i underlaget
1. Det finns ingen utdata från hej/overtrad-testet mot port 7524. Därför är det inte belagt att zonvakt nekas skriva i /etc men fortfarande svarar.
2. Det finns ingen utdata från curl mot /zon/kvitto.txt, så statuskod 200 är inte belagd.
3. Det finns ingen utdata från grep -n "dport" /etc/nftables/zon.nft eller från sudo nft list chain inet zon in. Åtgärd 4 är helt overifierad.
4. Flödestabellen, inklusive D1–D7 och vad "ctf" och CTF-SERVER motsvarar för adresser, ingår inte i underlaget.
5. Källkoden till /usr/local/bin/verifiera-hardning saknas, så det går inte att se exakt vad varje GÄLLER-rad testar.
6. Det finns inget belägg för en faktisk omstart i enforcing, bara att konfigurationsfilen är rätt.
7. Det framgår inte om filen /etc/zonvakt-otillaten från det tidigare intrånget har tagits bort.
8. Själva policymodulen (.te/.fc) och listan över tillåtna regler är inte bifogade.
9. Ursprungliga AVC-poster och kärnloggrader (ZON-IN-DROP) finns bara återgivna i text, inte som utdata.
10. Det finns ingen åtgärdsplan för den för breda corenet_tcp_bind_generic_port, till exempel en egen porttyp för 7524.
11. Uppgiften om Rocky Linux 9 och SELinux targeted bygger bara på din beskrivning. Det finns ingen utdata som visar till exempel /etc/os-release eller sestatus.
````

## 4. Rättelselogg – en rad per ändrat påstående

Alla 24 påståenden är dömda i [hardningsrapport.md](hardningsrapport.md). Kommandona som avgjorde domarna kördes på servern 2026-11-25, utan sudo. AI-assistenten körde kommandona över SSH och skrev ihop domarna, och varje dom bygger på en utskrift från servern. Här är de som ändrades:

| Påst. nr | Påstående (kort) | Dom | Kommando som avgjorde | Faktiskt utfall | Feltyp | Ändrat till |
|---|---|---|---|---|---|---|
| P4 | "inte prövats med en omstart" | fel | `uptime -s`, `sestatus`, `ctf-status` | Start 2026-11-17 12:52:25, enforcing efter starten, U7.5 LÖST | Ogrundat – omstarten fanns inte i underlaget | Servern startades om 2026-11-17 och står i enforcing efter omstarten |
| P5 | "nekas och loggas som AVC" | fel (delvis) | `sesearch --dontaudit -s domain -t domain -c tcp_socket` | `dontaudit domain domain:tcp_socket { read write };` | Överdrift i eget underlag (härdningslistan) | Otillåtna åtgärder nekas. Nekanden som täcks av dontaudit loggas inte |
| P14 | "vilken oreserverad port som helst" | stämmer (förtydligat) | `sesearch -A -s zonvakt_t -c tcp_socket -p name_bind` | `port_t`, `unreserved_port_t`, `ephemeral_port_t` | Ogrundat i underlaget | zonvakt_t får binda generella porttyper. Egen porttyp (U7.6) är inte gjord |
| P19 | "curl 200 inte verifierat" | fel | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/zon/kvitto.txt` | 200 | Ogrundat – utdatan fanns inte i underlaget | httpd serverar kvittot med 200 i enforcing |
| P21 | "D8 och D9" | fel (delvis) | `grep -n dport /etc/nftables/zon.nft` | tcp/80: kommentar "U7.2 ctf hämtar kvittot". tcp/7524: "D9" | Fel i eget underlag (härdningslistan) | ctf till tcp/80 (U7.2) och tcp/7524 (D9). Raden för tcp/80 saknar D-nummer |
| P22 | "D8 och D9 inte verifierat" | fel (delvis) | `grep -n dport /etc/nftables/zon.nft`, `ss -tln` | Reglerna finns i filen. Aktiva regler ej lästa (kräver sudo) | Ogrundat i underlaget | Reglerna finns i zon.nft. Aktiva brandväggen inte kontrollerad |

**Iakttagelse:** AI-utkastet hittade inte på något – inga påhittade filer, direktiv eller flaggor och inga förväxlade system. Två fel kom från mitt eget underlag (D8 i härdningslistan och "loggas som AVC"). De övriga var saker utkastet med rätta markerade som overifierade, och som servern sedan avgjorde (omstart, curl, zon.nft). Det som gav domen var kommandona på servern, inte hur säkert texten lät.

## 5. Utelämningslista – vad som medvetet inte matades in, och varför

- **zon.nft och flödestabellen:** innehåller adresserna till jump, ctf-servern, loggservern och zonerna. Tillsammans är det en karta över nätet. Reglerna som behövdes beskrivs i härdningslistan med `CTF-SERVER` i stället för adressen.
- **Serverns adresser och adressplanen:** inte publika. Behövdes inte för utkastet.
- **zonvakt.te och zonvakt.fc:** utelämnade för att hålla underlaget kort. Policyns innehåll sammanfattas i policyanteckningen och kontrollerades i stället direkt på servern (P11–P14).
- **Skriptets källkod:** utelämnad för att hålla underlaget kort. Den ligger i repot och är jämförd med servern (P24).
- **AVC-rader och kärnloggrader i rå form:** innehåller adresser och löpnummer från servern. Sammanfattade i härdningslistan.
- **Lösenord, tokens, SSH-nycklar och flaggor:** aldrig inmatade.
