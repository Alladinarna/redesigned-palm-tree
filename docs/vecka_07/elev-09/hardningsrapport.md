## Domar

| Nr | Påstående | Dom | Belägg |
|---|---|---|---|
| 1 | Servern kör Rocky Linux 9 | stämmer | `cat /etc/redhat-release`: Rocky Linux release 9.8 |
| 2 | Servern heter elev-09 | stämmer | `hostname`: elev-09 |
| 3 | SELinux är påslaget och använder policyn targeted | stämmer | `sestatus`: enabled, targeted |
| 4 | Current mode är enforcing | stämmer | `sestatus`: Current mode enforcing |
| 5 | Mode from config file är enforcing, gäller även efter omstart | stämmer | `sestatus`: Mode from config file enforcing |
| 6 | Före åtgärden körde zonvakt som root och kunde skriva i /etc | stämmer | `zonvakt.log` 17/11 13:37: "OBS: skrev till /etc". AVC: `uid=0` |
| 7 | Överträdelser nekas och loggas som AVC | stämmer | `ausearch -m avc`: `denied { write }`, `permissive=0` |
| 8 | Åtgärden görs med ett skript | fel | se rättelseloggen |
| 9 | En policymodul som heter zonvakt är installerad | stämmer | `sudo semodule -l \| grep zonvakt`: zonvakt |
| 10 | Processen zonvakt kör i domänen zonvakt_t | stämmer | `ps -eZ \| grep zonvakt`: zonvakt_t |
| 11 | Domänen är inte permissive | stämmer | `sudo semanage permissive -l \| grep zonvakt`: tomt. AVC: `permissive=0` |
| 12 | Före åtgärden körde zonvakt i unconfined_service_t | stämmer | `ps -eZ` 17/11 före policyn: unconfined_service_t |
| 13 | Före åtgärden stoppade varken DAC eller MAC skrivning i /etc | stämmer | `zonvakt.log` 13:37: "OBS: skrev till /etc", `uid=0` |
| 14 | zonvakt nekas att skriva i /etc | stämmer | `echo overtrad \| nc 127.0.0.1 7509`: nekad. AVC: `denied { write }` på etc_t |
| 15 | zonvakt svarar ok på vanliga anslutningar | stämmer | `echo hej \| nc 127.0.0.1 7509`: ok |
| 16 | zon.nft har policy drop i både in och ut | stämmer | `sudo nft list ruleset`: policy drop i in och ut |
| 17 | Bara flöden med en D- eller F-rad släpps igenom | fel | se rättelseloggen |
| 18 | Trafik som kastas loggas som ZON-IN-DROP eller ZON-UT-DROP | fel | se rättelseloggen |
| 19 | Fångsten från vecka 1 visade trafik till port 4444 | stämmer | Lagerkartan i repot: TCP-trafik till port 4444 |
| 20 | Testprotokollet är från vecka 4 och uppdaterades inte efter bytet till 6514 | stämmer | Testprotokollen i `vecka_04/elev-09/Bevis`: D5 testar 514 |
| 21 | Inget visar att utgående TCP 6514 släpps ut | fel | se rättelseloggen |
| 22 | rsyslog skickar loggarna på TCP 6514 med gtls | stämmer | `cat /etc/rsyslog.d/90-logg.conf`: port 6514, gtls |
| 23 | Klartext på port 514 är borttagen | stämmer | `grep -rn 514 /etc/rsyslog.conf /etc/rsyslog.d/`: bara avstängda rader och 6514 |
| 24 | Testraden "test elev-09" kom fram i Wazuh | stämmer | Wazuh, wazuh-archives-*: träff från /var/log/remote/elev-09/syslog.log |
| 25 | Det framgår inte om rsyslog kontrollerar certifikatet | fel | se rättelseloggen |
| 26 | Bara konfigurationen anges som skriptad | stämmer | Härdningslistan, rad 4: "Ja (konfigurationen)" |

## Rättelselogg

| Nr | Påstående | Dom | Kommando som avgjorde | Faktiskt utfall | Feltyp | Ändrat till |
|---|---|---|---|---|---|---|
| 8 | Åtgärden görs med ett skript | fel | `getenforce \| grep -q Enforcing && echo GÄLLER` | Kolumnen "Skript?" betyder att ett skript kan verifiera åtgärden, inte utföra den | Faktafel (feltolkning) | Åtgärden kan verifieras med ett skript |
| 17 | Bara flöden med en D- eller F-rad släpps igenom | fel | `sudo nft list ruleset` | lo, established/related och invalid hanteras utan D/F-rad | Överdrift | Alla nya flöden behöver en D- eller F-rad. Loopback och svar på godkända anslutningar släpps alltid |
| 18 | Trafik som kastas loggas som ZON-IN-DROP eller ZON-UT-DROP | fel | `sudo nft list ruleset`, `sudo journalctl -k \| grep ZON` | Loggregeln har limit rate 10/minute | Överdrift | Trafik som kastas loggas, högst 10 rader per minut |
| 21 | Inget visar att utgående TCP 6514 släpps ut. Loggarna når aldrig loggservern | fel | `sudo nft list ruleset`, `logger "test elev-09"` + Wazuh | D5 släpper 6514 ut. Testraden kom fram i Wazuh | Ogrundat | Utgående TCP 6514 till loggservern släpps av D5. Testrad verifierad i Wazuh |
| 25 | Det framgår inte om rsyslog kontrollerar loggserverns certifikat | fel | `cat /etc/rsyslog.d/90-logg.conf` | `StreamDriverAuthMode="x509/name"` och `PermittedPeers` | Ogrundat | rsyslog kontrollerar loggserverns certifikat och namn (x509/name) |
