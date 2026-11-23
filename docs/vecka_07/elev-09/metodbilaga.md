# Metodbilaga – elev-09

Prompten och AI:ns svar ligger i kodrutor så att texten visas exakt som den skickades och kom tillbaka, utan ändringar.

## 1. Underlag som matades in

- Härdningslistan (hardningslista.md)
- Utdata från `sestatus`
- Utdata från `sudo semodule -l | grep zonvakt`
- Utdata från `ps -eZ | grep zonvakt`

Inga värden behövde maskeras. Underlaget innehöll inga IP-adresser, lösenord, nycklar eller flaggor.

## 2. Prompt, ordagrant

Jag gick igenom med en AI-assistent vad prompten skulle innehålla och bestämde fem punkter. AI:n satte ihop dem till en prompt, och jag skickade den utan ändringar i en ny chatt.

```
Skriv ett utkast till en härdningsrapport för min server. Jag arbetar på Rocky Linux 9 med SELinux targeted.

Regler:
- Håll dig bara till underlaget nedan.
- Skriv rapporten som numrerade påståenden, ett per rad.
- Markera tydligt det som inte finns i underlaget.

Underlag:

Härdningslista:

| Nr | Åtgärd | Motivering | Förväntad effekt | Verifiering | Skript? |
|---|---|---|---|---|---|
| 1 | SELinux i enforcing, nu och efter omstart | Utan enforcing stoppas inget. Zonvakt körde som root och kunde skriva i /etc. I permissive hade det bara loggats | Överträdelser nekas (Permission denied) och loggas som AVC | sestatus: Current mode och Mode from config file = enforcing | Ja |
| 2 | Zonvakt under egen tvingande policy: egen domän zonvakt_t, permissive borttagen | Utan egen policy körde zonvakt som root i unconfined_service_t och kunde skriva i /etc. Varken DAC eller MAC stoppade det | Zonvakt kan inte längre skriva i /etc (nekad), men svarar fortfarande ok på vanliga anslutningar | ps -eZ \| grep zonvakt = zonvakt_t. echo hej ger ok, echo overtrad ger nekad | Ja |
| 3 | Default deny i zon.nft: policy drop i både in och ut. Bara flöden med en D- eller F-rad släpps igenom | Utan policy drop kan vem som helst nå servern in, och en kapad server kan ringa hem ut, som trafiken till port 4444 i min fångst från vecka 1 | Trafik utan D- eller F-rad kastas och loggas som ZON-IN-DROP eller ZON-UT-DROP | sudo nft list ruleset visar policy drop i in och ut. test.sh med testfall.csv, testprotokoll i vecka_04 (från vecka 4, ej uppdaterat efter 6514) | Ja |
| 4 | Systemloggen skickas krypterat med TLS till loggservern på TCP 6514. Klartext på 514 är borttagen | I klartext kan vem som helst på vägen läsa loggarna. Ligger de bara lokalt kan en angripare som blir root radera dem och sudda ut spåren | Loggarna går krypterat, så ingen på vägen kan läsa dem. En kopia finns på loggservern, så spåren finns kvar även om elev-09 tas över | logger "test elev-09", sedan sök i Wazuh (wazuh-archives-*), raden kommer fram. /etc/rsyslog.d/90-logg.conf visar port 6514 och gtls | Ja (konfigurationen) |

Utdata från sestatus:

SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      33

Utdata från sudo semodule -l | grep zonvakt:

zonvakt

Utdata från ps -eZ | grep zonvakt:

system_u:system_r:zonvakt_t:s0    47259 ?        00:00:00 zonvakt
```

## 3. Råsvar, oredigerat

```
Härdningsrapport elev-09 (utkast)

Markeringar

[UTDATA]: visas i utdata i underlaget
[LISTA]: står bara i härdningslistan, utan utdata som bevisar det
[SAKNAS]: finns inte i underlaget

System

Servern kör Rocky Linux 9. [SAKNAS: det står bara i din fråga, inte i någon utdata]
Servern heter elev-09. [LISTA]
SELinux är påslaget och använder policyn targeted. [UTDATA: sestatus]

Åtgärd 1: SELinux i enforcing
4. Current mode är enforcing. [UTDATA: sestatus]
5. Mode from config file är enforcing. Därför gäller enforcing även efter omstart. [UTDATA: sestatus]
6. Före åtgärden körde zonvakt som root och kunde skriva i /etc. [LISTA]
7. Överträdelser nekas och loggas som AVC. [SAKNAS: ingen AVC-rad finns med]
8. Åtgärden görs med ett skript. [LISTA. Skriptet finns inte med: SAKNAS]

Åtgärd 2: zonvakt under egen policy
9. En policymodul som heter zonvakt är installerad. [UTDATA: semodule -l]
10. Processen zonvakt (PID 47259) kör i domänen zonvakt_t. [UTDATA: ps -eZ]
11. Ingen permissive-modul för zonvakt syns i semodule-listan. [UTDATA, men bara indirekt. Det finns ingen direkt kontroll, till exempel semanage permissive -l: SAKNAS]
12. Före åtgärden körde zonvakt i unconfined_service_t. [LISTA]
13. Före åtgärden stoppade varken DAC eller MAC skrivning i /etc. [LISTA]
14. zonvakt nekas att skriva i /etc. [SAKNAS: ingen utdata från echo overtrad, ingen AVC]
15. zonvakt svarar ok på vanliga anslutningar. [SAKNAS: ingen utdata från echo hej]

Åtgärd 3: Default deny i zon.nft
16. zon.nft har policy drop i både in och ut. [SAKNAS: ingen utdata från nft list ruleset]
17. Bara flöden som har en D- eller F-rad släpps igenom. [LISTA]
18. Trafik som
