# Härdningsrapport – elev-38 (databasservern)

AI-utkastet (P1–P28, råsvaret i [metodbilaga.md](metodbilaga.md)) är dömt påstående för påstående mot servern. Alla kontroller gjordes 2026-11-23 på elev-38. Alla tider i UTC.
Dom: **stämmer** = servern bekräftar · **fel** = servern motsäger · **ogrundat** = servern avgör inte · **inaktuellt** = var sant före en ändring.

## Domar

| Nr | Påstående (kort) | Dom | Belägg |
|---|---|---|---|
| P1 | Rocky Linux 9, SELinux targeted, databasservern i ett team på fyra | fel (delvis) | `cat /etc/redhat-release`: Rocky Linux release 9.8. `sestatus`: Loaded policy name targeted. Men `sudo ss -tlnp \| grep 5432`: inget lyssnar – ingen databas körs (se rättelseloggen) |
| P2 | SELinux står i Enforcing just nu | stämmer | `getenforce`: Enforcing. Skriptet rad 1: GÄLLER |
| P3 | `/etc/selinux/config` innehåller `SELINUX=enforcing` | stämmer | `grep ^SELINUX= /etc/selinux/config`: SELINUX=enforcing |
| P4 | Enforcing gäller även efter omstart | stämmer | Skriptet efter omstart, rad 1–2: GÄLLER. `kontrollera U7.5` godkänd |
| P5 | Utan MAC går root förbi DAC, och `setenforce` försvinner vid omstart | stämmer | Före policyn skrev zonvakt (root) `/etc/zonvakt-otillaten` – DAC stoppade inte. `man setenforce`: ändrar bara läget tills vidare, config gäller vid uppstart |
| P6 | Före åtgärden: `unconfined_service_t`, kunde skriva `/etc/zonvakt-otillaten` | stämmer | `ps -eZ`: `unconfined_service_t` (pid 26190). `echo overtrad`: "OBS: skrev till /etc/zonvakt-otillaten". `ls -l`: filen fanns, ägare root, 06:32 |
| P7 | Policymodulen zonvakt är laddad | stämmer | Skriptet rad 3 (`semodule -l`): GÄLLER |
| P8 | zonvakt kör i `zonvakt_t` (PID 26385) | inaktuellt | Domänen stämmer: `ps -eo user,label,comm`: `zonvakt_t`. Men PID 26385 är från före omstarten – nu pid 986 (`ss -tlnp`) |
| P9 | `zonvakt_t` är inte permissiv | stämmer | `sudo semanage permissive -l \| grep zonvakt`: tomt. Skriptet rad 5: GÄLLER |
| P10 | zonvakt kör som root | stämmer | `ps -eo user,label,comm \| grep zonvakt`: root |
| P11 | zonvakt använder port 7538 | stämmer | `sudo ss -tlnp`: LISTEN 0.0.0.0:7538, users "zonvakt" |
| P12 | overtrad nekades med "nekad: Permission denied" | stämmer | `echo overtrad \| nc -w2 127.0.0.1 7538`: "zonvakt elev-38 nekad: Permission denied". `ls -l /etc/zonvakt-otillaten`: No such file |
| P13 | AVC `denied { write }` på `etc_t`, `permissive=0` | stämmer | `ausearch -m avc -c zonvakt`: löpnummer 2495 (06:41:46, eget test) och 2536 (06:42:23, ctf-servern), `denied { write }`, `tcontext=…etc_t`, `tclass=dir`, `permissive=0` |
| P14 | Samma AVC-rad syns i Wazuh med rule.id 100200 | stämmer | Discover, `wazuh-archives-*`, `full_log:"type=AVC" and full_log:"comm=zonvakt"`: träff 06:42:23, audisp-syslog, rule.id 100200, nivå 5 |
| P15 | hej fungerar | stämmer | `echo hej \| nc -w2 127.0.0.1 7538`: "zonvakt elev-38 ok" |
| P16 | Före: httpd gav 403, AVC `getattr` på `var_t` | stämmer | `curl`: 403. `ausearch`: löpnummer 1859, `denied { getattr }`, `httpd_t` → `var_t`, `permissive=0` |
| P17 | Satt med `semanage fcontext` + `restorecon`, inte `chcon` | stämmer | Körde `semanage fcontext -a -t httpd_sys_content_t '/srv/zonwebb(/.*)?'` och `restorecon -Rv /srv/zonwebb`. `chcon` användes inte |
| P18 | Bestående fcontext-regel finns | stämmer | Skriptet rad 6 (`semanage fcontext -l -C`): GÄLLER |
| P19 | `/srv/zonwebb` har typen `httpd_sys_content_t` | stämmer | `restorecon -Rv`: var_t → httpd_sys_content_t. Skriptet rad 7: GÄLLER |
| P20 | httpd kan läsa katalogen, curl gav kvittot | stämmer | `curl http://127.0.0.1/zon/kvitto.txt`: kvittoraden. `kontrollera U7.2`: ctf-servern hämtade sidan |
| P21 | Märkningen tål en relabel | stämmer | `matchpathcon /srv/zonwebb /srv/zonwebb/kvitto.txt`: båda `httpd_sys_content_t` – det är den typ en relabel sätter. Ingen relabel kördes |
| P22 | Kedjan `in` i `inet zon` har policy drop | stämmer | `sudo nft list chain inet zon in`, rad 3: `policy drop` |
| P23 | nftables startar vid omstart | stämmer | Skriptet rad 9 (`systemctl is-enabled nftables`): GÄLLER |
| P24 | Två nya flöden från CTF-SERVER: tcp/80 och tcp/7538 | stämmer | `nft list chain`, rad 9–10: `ip saddr <CTF-SERVER> tcp dport 80 accept` och `… 7538 accept` |
| P25 | Reglerna ligger före loggregeln ZON-IN-DROP | stämmer | `nft list chain`: reglerna på rad 9–10, loggregeln på rad 13 |
| P26 | Bara CTF-SERVER når portarna, allt annat nekas **och loggas** | fel | `nft list chain`, rad 13: `limit rate 10/minute burst 5 packets log` – allt loggas inte (se rättelseloggen) |
| P27 | Skriptet efter omstart: nio GÄLLER, felkod 0 | stämmer | `sudo /usr/local/bin/verifiera-hardning; echo "felkod: $?"` efter omstart: nio GÄLLER, felkod 0 |
| P28 | Alla fyra åtgärder är markerade "Skript? Ja" | stämmer | Härdningslistan. "Ja" betyder att skriptet verifierar åtgärden – för nr 2 och 4 bara en del (se rättelseloggen) |

## Rättelselogg

| Nr | Påstående (kort) | Dom | Kommando som avgjorde | Faktiskt utfall | Feltyp | Ändrat till |
|---|---|---|---|---|---|---|
| P1 | "databasservern" | fel (delvis) | `sudo ss -tlnp \| grep 5432` | Ingen tjänst lyssnar på 5432 | Fel i eget underlag (prompten). AI:n återgav prompten och flaggade själv luckan (lucka 1) | elev-38 representerar Databaszonen i teamets zonmodell. Ingen databastjänst körs ännu, men flödet F10 (5432 från Serverzonen) är förberett i zon.nft |
| P8 | PID 26385 | inaktuellt | `sudo ss -tlnp` | zonvakt har pid 986 efter omstarten | Inaktuellt – U3 togs före omstarten | zonvakt kör i `zonvakt_t` (PID ändras vid omstart och anges inte) |
| P26 | "allt annat nekas och loggas" | fel | `sudo nft list chain inet zon in` | Loggregeln har `limit rate 10/minute burst 5 packets` | Fel i eget underlag (överdrift i härdningslistan) | All annan ny trafik in nekas (policy drop). Nekandena loggas, men högst 10 rader per minut (burst 5) |
| P28 | "Skript? Ja" | stämmer (förtydligat) | `cat /usr/local/bin/verifiera-hardning` | Skriptet kontrollerar domän, modul och permissiv (nr 2) och policy drop och uppstart (nr 4), men inte overtrad, AVC-raden eller de två nft-reglerna | Ogrundat i underlaget – skriptets innehåll fanns inte med | "Ja" = åtgärden verifieras med skriptet. För nr 2 och 4 verifieras resten manuellt (P12–P14, P24–P25) |

## Luckorna i AI-utkastet – vad jag gjorde med dem

| Lucka | Bedömning |
|---|---|
| 1. Databasen saknas | Stämmer – se P1 |
| 2. OS och policytyp | Kontrollerat – se P1 |
| 3. Skriptets innehåll | Skriptet ligger i repot: [verifiera-hardning](verifiera-hardning) |
| 4. Uppgifter om körningen | Stämmer – U3 var före omstarten (P8). Datum och tider står nu i domarna |
| 5. Lägena före åtgärderna | Kontrollerat med utskrifter från arbetet – se P6, P16 |
| 6. zonvakt inte fullt verifierad | Kontrollerat – se P10, P11, P15 |
| 7. httpd inte fullt verifierad | Kontrollerat – se P20, P21 |
| 8. Paketfiltret inte fullt verifierat | Ordning och regler kontrollerade (P24, P25). Negativt test från en annan värd och ZON-IN-DROP-rad: inte gjort, finns i vecka 6 (detektion 2) |
| 9. Skriptet täcker inte allt | Stämmer – se P28 |
| 10. Wazuh-regel 100200 | Lagt till av kursen på loggservern (veckoguiden), inte min konfiguration |
| 11. Teamets roller | elev-38 är Naimas server. Övriga i teamet har egna mappar i `docs/vecka_07/` |
