## Rapport
 
### Härdningsrapport – webbserver (Rocky Linux 9) – utkast
 
18 nov. 2026 · Hugo Wester
 
#### Omfattning och läsanvisning
 
Av sex planerade härdningsåtgärder är tre belagda i underlaget (3, 5, 6), två är inte genomförda (1, 2) och en saknar belägg (4). Varje påstående är numrerat (P1, P2 …) och har en källhänvisning så att det kan granskas ett och ett.
 
Källförkortningar: HL n = härdningslistan, rad n · SES = sestatus · SEM = semodule -l \| grep zonvakt · PS = ps -eZ \| grep zonvakt · SKR = utdata från verifiera-hardning · TE = ~/policy/zonvakt.te · CONF = /etc/httpd/conf.d/hardning.conf · UPPDR = uppdragsbeskrivningen.
 
P1. Servern kör Rocky Linux 9 med SELinux och representerar webbservern i teamets miljö, som består av fyra personer. (UPPDR)
 
P2. Härdningslistan omfattar sex åtgärder. (HL 1–6)
 
P3. Åtgärd 1 och 2 (SSH) är planerade men ännu inte genomförda. (HL 1–2)
 
P4. Underlaget sammanställdes 2026-11-18. (inmatningspaketets rubrik)
 
#### Åtgärd 1 – Stäng av lösenordsinloggning i SSH
 
*Status: planerad, ej genomförd.*
 
**Åtgärd**
 
P5. Åtgärden är ännu inte genomförd. (HL 1)
 
P6. Enligt härdningslistan visade sshd -T passwordauthentication yes. (HL 1)
 
P7. När lösenordsinloggning är tillåten kan en angripare försöka gissa sig till lösenordet och logga in. (HL 1)
 
P8. Åtgärden innebär att lösenordsinloggning i SSH stängs av. (HL 1)
 
**Effekt**
 
P9. En angripare ska inte kunna gissa sig till lösenordet genom bruteforce. (HL 1)
 
**Verifiering**
 
P10. sshd -T ska visa passwordauthentication no. (HL 1)
 
P11. Kontrollen ska ingå i verifieringsskriptet men finns inte där ännu. (HL 1; SKR saknar SSH-rader)
 
#### Åtgärd 2 – Förbjud root-inloggning i SSH
 
*Status: planerad, ej genomförd.*
 
**Åtgärd**
 
P12. Åtgärden är ännu inte genomförd. (HL 2)
 
P13. Enligt härdningslistan visade sshd -T permitrootlogin without-password. (HL 2)
 
P14. Med root kommer man åt allt på servern, medan kontot student är mer begränsat. (HL 2)
 
P15. Åtgärden innebär att root-inloggning via SSH förbjuds helt. (HL 2)
 
**Effekt**
 
P16. En angripare ska inte kunna logga in direkt som root utan måste först gå via ett användarkonto, vilket ger ett extra hinder. (HL 2)
 
**Verifiering**
 
P17. sshd -T ska visa permitrootlogin no. (HL 2)
 
P18. Kontrollen ska ingå i verifieringsskriptet men finns inte där ännu. (HL 2; SKR saknar SSH-rader)
 
#### Åtgärd 3 – Dölj Apache-versionen i Server-headern
 
*Status: genomförd. Enligt skriptet uppfyller den kriteriet, men curl-utdata efter ändringen saknas.*
 
**Åtgärd**
 
P19. Före åtgärden visade curl -I headern Server: Apache/2.4.62 (rocky Linux). (HL 3)
 
P20. Med den exakta versionen kan en angripare slå upp kända sårbarheter. (HL 3)
 
P21. Filen /etc/httpd/conf.d/hardning.conf innehåller direktivet ServerTokens Prod. (CONF)
 
**Effekt**
 
P22. En angripare ska inte kunna få reda på versionen via Server-headern. (HL 3)
 
**Verifiering**
 
P23. curl -I ska visa Server: Apache utan version. (HL 3)
 
P24. Verifieringsskriptet rapporterar ”GÄLLER httpd visar inte versionen i Server-headern”. (SKR)
 
#### Åtgärd 4 – Uppdatera systemet
 
Status: genomförd och verifierad manuellt. dnf check-update gav felkod 0 (inga väntande uppdateringar) 2026-11-18. Ingår inte i skriptet, se P29–P30. (rättad, se rättelselogg)

**Åtgärd**
 
P25. Uppdateringar täpper till kända säkerhetshål som tillverkaren har hittat. (HL 4)
 
P26. Åtgärden innebär att systemet uppdateras. (HL 4)
 
**Effekt**
 
P27. Kända sårbarheter ska vara täppta. (HL 4)
 
**Verifiering**
 
P28. dnf check-update ska ge felkod 0. (HL 4)
 
P29. Kontrollen görs manuellt och ingår inte i skriptet. (HL 4)
 
P30. Skälet är att nya uppdateringar släpps löpande. Skriptet skulle då kunna rapportera GÄLLER INTE trots att inget har ändrats på servern. (HL 4)
 
#### Åtgärd 5 – SELinux i enforcing nu och efter omstart
 
*Status: genomförd och verifierad både med sestatus och med skriptet.*
 
**Åtgärd**
 
P31. SELinux sätts i tvingande läge (enforcing) både i det körande systemet och i /etc/selinux/config, så att läget gäller även efter omstart. (HL 5)
 
P32. Om en angripare tar över en tjänst kan den bara göra det som tjänstens domän tillåter, även om tjänsten kör som root. (HL 5)
 
P33. Utan enforcing gäller bara DAC, och root går förbi DAC. (HL 5)
 
**Effekt**
 
P34. Otillåtna åtgärder ska nekas och loggas som AVC. (HL 5)
 
**Verifiering**
 
P35. getenforce ska ge Enforcing och grep ^SELINUX= /etc/selinux/config ska ge SELINUX=enforcing. (HL 5)
 
P36. sestatus visar SELinux status: enabled, Current mode: enforcing och Mode from config file: enforcing. (SES)
 
P37. sestatus visar att den laddade policyn är targeted. (SES)
 
P38. Skriptet rapporterar GÄLLER för tvingande läge nu (getenforce = Enforcing) och för enforcing efter omstart (/etc/selinux/config). (SKR)
 
#### Åtgärd 6 – Egen tvingande SELinux-policy för zonvakt
 
Status: genomförd och verifierad. ps -eZ visar zonvakt_t och semanage permissive -l visar inte zonvakt_t. Policyn ger fler rättigheter än den ursprungliga effektbeskrivningen nämnde, se P46 och P49–P51. (rättad, se rättelselogg) 

**Åtgärd**
 
P39. Tjänsten zonvakt kör som root. (HL 6)
 
P40. Före åtgärden hamnade zonvakt i domänen unconfined_service_t. (HL 6)
 
P41. I det läget kunde overtrad skriva i /etc. Om någon tar över tjänsten kan den dårför ändra systemets inställningar. (HL 6)
 
P42. Policymodulen zonvakt (version 1.0.0) definierar domänen zonvakt_t, typen zonvakt_exec_t för programfilen och typen zonvakt_log_t för loggfiler. (TE)
 
P43. Modulen gör zonvakt_t till en daemon-domän som startas via init (init_daemon_domain(zonvakt_t, zonvakt_exec_t)). (TE)
 
P44. Modulen är laddad i systemet. (SEM)
 
P45. Den visade .te-filen innehåller ingen rad som sätter zonvakt_t i permissive-läge. (TE)
 
**Effekt**
 
P46. Zonvakt får lyssna på valfri oreserverad port, svara, skriva i sin egen logg, läsa i /etc och /etc/passwd och köra python3. Den får inte skriva i /etc. Begränsning till enbart port 7546 återstår (U7.6). (TE – rättad, se rättelselogg) 
P47. overtrad ska nekas och loggas som AVC. (HL 6)
 
P48. Policyn ger zonvakt_t rätt att hantera kataloger, filer och länkar av typen zonvakt_log_t, och att skapa sådana i loggkatalogen (logging_log_filetrans). (TE)
 
P49. Policyn ger också rättigheter utöver de tre som effektbeskrivningen nämner. (TE)
 
- files_read_etc_files – läsa filer i /etc
- auth_read_passwd_file – läsa passwd-filen
- corecmd_exec_bin – köra program i bin-kataloger
- miscfiles_read_localization – läsa lokaliseringsfiler
- sssd_search_lib, sssd_read_public_files – läsa SSSD:s publika filer
- domain_use_interactive_fds, samt fifo- och unix_stream_socket-rättigheter mot sig själv
P50. Policyn definierar ingen egen porttyp för zonvakt. Rätten att binda TCP ges via de generella gränssnitten corenet_tcp_bind_generic_port och corenet_tcp_bind_generic_node. (TE)
 
P51. Ingen regel i den visade .te-filen ger uttryckligen skrivrätt i /etc. Det enda /etc-gränssnittet är files_read_etc_files. (TE)
 
**Verifiering**
 
P52. ps -eZ ska visa zonvakt_t och semanage permissive -l ska inte visa zonvakt_t. (HL 6)
 
P53. ps -eZ visar zonvakt-processen (PID 1001) med kontexten system_u:system_r:zonvakt_t:s0. (PS)
 
P54. Skriptet rapporterar ”GÄLLER zonvakt kör i egen domän zonvakt_t”. (SKR)
 
P55. Utdata från semanage permissive -l finns inte i underlaget, och skriptet kontrollerar inte permissive-läget. (SKR)
 
#### Samlad verifiering
 
P56. verifiera-hardning gav fyra GÄLLER-rader och slutkod 0. (SKR)
 
P57. Skriptet täcker åtgärd 3, 5 och 6 (den senare bara domänkontrollen), men inte åtgärd 1, 2 och 4. (SKR, HL 1–6)
 
| Åtgärd | I skriptet | Resultat i underlaget |
|---|---|---|
| 1 SSH lösenord | Nej (planerad) | – |
| 2 SSH root | Nej (planerad) | – |
| 3 Server-header | Ja | GÄLLER |
| 4 Uppdatering | Nej (manuell) | Ingen utdata |
| 5 SELinux enforcing | Ja, två kontroller | GÄLLER, GÄLLER |
| 6 zonvakt-policy | Delvis (bara domänen) | GÄLLER, permissive-kontroll saknas |
 
#### Luckor i underlaget
 
L1. Före-lägen utan råutdata. sshd -T (P6, P13), curl -I (P19), unconfined_service_t (P40) och overtrad mot /etc (P41) återges bara i härdningslistan. Kommandoutskrifterna finns inte med.
 
L2. Åtgärd 4 saknar helt belägg. Det finns ingen dnf-utdata, varken från själva uppdateringen eller från dnf check-update.
 
L3. Åtgärd 3 – ingen curl -I efter ändringen. Det enda belägget är skriptets slutsats (P24). hardning.conf ser dessutom avkortad ut (kodblocket avslutas inte), så det är oklart om filen har fler rader.
 
L4. Åtgärd 6 – permissive-kontrollen saknas. Utdata från semanage permissive -l saknas trots att den är halva verifieringskriteriet (P52, P55).
 
L5. Inget negativt test. Det finns inget som visar att overtrad faktiskt nekas efter åtgärden, och inga AVC-poster. Det gäller både P34 och P47.
 
L6. Effektbeskrivningen och policyn stämmer inte överens. P46 säger ”bara lyssna på sin port, svara och skriva i sin egen logg”, men .te-filen ger fler rättigheter (P49) och ingen egen port (P50). Antingen texten eller policyn behöver justeras.
 
L7. Filkontexter saknas. Underlaget saknar .fc-filen och ls -Z, så det framgår inte vilka sökvägar som märks zonvakt_exec_t och zonvakt_log_t.
 
L8. Visad .te kontra laddad modul. Det går inte att se att den visade .te-filen är exakt den version som är laddad. semodule -l visar bara namnet.
 
L9. Skriptets källkod saknas. Det går inte att se hur kontrollerna görs, till exempel vilken adress httpd-kontrollen anropar.
 
L10. Ingen värd eller tidpunkt på utskrifterna. Kommandoutdata saknar värdnamn och tidsstämpel och kan därför inte knytas till en viss server eller tidpunkt.
 
L11. overtrad beskrivs inte. Det framgår inte vad overtrad är eller hur den körs.
 
L12. Inloggningsväg efter åtgärd 1 och 2. Underlaget visar inte att kontot student kan logga in med något annat än lösenord. Om båda åtgärderna genomförs krävs en annan fungerande inloggningsväg.


## Granskning av påståenden

| Påstående | Dom | Belägg |
|---|---|---|
| P1 | stämmer | cat /etc/os-release ger Rocky Linux 9.9, getenforce ger Enforcing, teamets zonmodell i repot |
| P2, P4 | stämmer | Härdningslista.md (6 åtgärder), inmatningspaket.md (datum) |
| P3, P5, P6, P12, P13 | stämmer | sudo sshd -T \| grep -iE 'permitrootlogin\|passwordauthentication' ger permitrootlogin without-password och passwordauthentication yes |
| P8, P9, P10, P15, P16, P17 | stämmer | Härdningslista.md rad 1 och 2 beskriver planerad åtgärd, effekt och verifiering. Inte genomfört än enligt sshd -T |
| P11, P18, P55, P56, P57 | stämmer | sudo /usr/local/bin/verifiera-hardning; echo $? ger 4 GÄLLER och felkod 0, cat på skriptet visar inga SSH- eller permissive-kontroller |
| P38, P54 | stämmer | Samma körning av verifiera-hardning: GÄLLER på båda SELinux-raderna och på zonvakt_t |
| P7, P14, P20, P25 | stämmer | Resonemang, källa MITRE ATT&CK T1110 (vecka 6), Red Hat Using SELinux kap 1 och CIS Benchmark |
| P32, P33 | stämmer | Red Hat kap 1 samt egen server: overtrad lyckades som root i unconfined_service_t 17/11 och nekades som root i zonvakt_t (ausearch -a 711 -i, permissive=0) |
| P19, P40, P41 | stämmer | Läget före åtgärden, tidigare utdata: curl -I 16/11 visade Apache/2.4.62 (Rocky Linux), ps -eZ 17/11 visade unconfined_service_t och overtrad skapade /etc/zonvakt-otillaten |
| P21, P22, P23, P24 | stämmer | cat /etc/httpd/conf.d/hardning.conf ger ServerTokens Prod och curl -I http://127.0.0.1 ger Server: Apache |
| P26, P27, P28 | stämmer | dnf check-update ger felkod 0, inga väntande uppdateringar |
| P29, P30 | stämmer | Härdningslista.md rad 4 och skriptet saknar en dnf-kontroll |
| P31, P35, P36, P37 | stämmer | sestatus ger SELinux status enabled, Current mode enforcing, Mode from config file enforcing och loaded policy targeted. grep ^SELINUX= /etc/selinux/config ger SELINUX=enforcing |
| P39 | stämmer | ps -o user= -C zonvakt ger root |
| P53 | stämmer | ps -eZ \| grep zonvakt ger system_u:system_r:zonvakt_t:s0 PID 1001 |
| P42, P43, P45, P48, P49, P50, P51 | stämmer | cat ~/policy/zonvakt.te visar type raderna, init_daemon_domain, ingen permissive rad, manage mönster för zonvakt_log_t, files_read_etc_files, auth_read_passwd_file, corecmd_exec_bin, corenet_tcp_bind_generic_port och generic_node, inget skrivmakro mot /etc |   |
| P44 | stämmer | sudo semodule -l \| grep zonvakt ger zonvakt |
| P34, P47 | stämmer| sudo ausearch -a 711 -i ger avc denied { write } för zonvakt_t mot etc_t, permissive=0, uid=root, success=no  |
| P46 | fel | cat ~/policy/zonvakt.te visar att zonvakt även får läsa i /etc och passwd, köra program i /usr/bin och binda valfri oreserverad port. Se rättelselogg |
| P52 | stämmer | Härdningslista.md rad 6. ps -eZ ger zonvakt_t och sudo semanage permissive -l visar inte zonvakt_t |
