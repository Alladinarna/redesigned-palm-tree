# Härdningsrapport – elev-24

AI-utkastet (P1–P24, råsvaret i [metodbilaga.md](metodbilaga.md)) är dömt påstående för påstående mot servern. Alla kontroller gjordes 2026-11-25 på elev-24, utan sudo. Alla tider i UTC (serverns tidszon är Etc/UTC).
Dom: **stämmer** = servern bekräftar · **fel** = servern motsäger · **ogrundat** = servern avgör inte · **inaktuellt** = var sant före en ändring.

## Domar

| Nr | Påstående (kort) | Dom | Belägg |
|---|---|---|---|
| P1 | Rocky Linux 9 med SELinux targeted | stämmer | `cat /etc/redhat-release`: Rocky Linux release 9.8 (Blue Onyx). `sestatus`: Loaded policy name targeted |
| P2 | SELinux är Enforcing i den körande kärnan | stämmer | `sestatus`: Current mode enforcing. Skriptet rad 1: GÄLLER |
| P3 | `/etc/selinux/config` är satt till enforcing | stämmer | `grep ^SELINUX= /etc/selinux/config`: SELINUX=enforcing |
| P4 | Att servern startar i enforcing har inte prövats med en omstart | fel | `uptime -s`: senaste start 2026-11-17 12:52:25. Läget är enforcing efter den starten. `ctf-status`: U7.5 Omstartstestet LÖST 2026-11-17 (se rättelseloggen) |
| P5 | Otillåtna åtgärder ska nekas och loggas som AVC | fel (delvis) | Nekas: stämmer (se P10). Loggas: `sesearch --dontaudit`: `dontaudit domain domain:tcp_socket { read write };` – sådana nekanden loggas inte (se rättelseloggen) |
| P6 | Före åtgärden: root i `unconfined_service_t`, overtrad skrev `/etc/zonvakt-otillaten` | ogrundat | Ingen utdata från före åtgärden finns sparad. `diff zonvakt.te.orig zonvakt.te`: originalet hade `permissive zonvakt_t;`. `ls -l /etc/zonvakt-otillaten`: No such file or directory |
| P7 | zonvakt kör i `zonvakt_t` (PID 995) | stämmer | `ps -eo user,label,pid,comm \| grep zonvakt`: `root system_u:system_r:zonvakt_t:s0 995 zonvakt`. Samma PID sedan omstarten 17/11 |
| P8 | zonvakt kör som root, begränsningen ligger på MAC | stämmer | `ps -eo user,…`: root |
| P9 | `zonvakt_t` är inte permissiv | stämmer | `seinfo --permissive`: 7 typer, zonvakt_t finns inte bland dem. Skriptet rad 4: GÄLLER |
| P10 | hej/overtrad-testet är inte verifierat | ogrundat | Testet kördes inte 2026-11-25 (det skriver en rad i tjänstens logg). `sesearch -A -s zonvakt_t -t etc_t -c dir -p write` och `… -c file -p create`: inga regler, så policyn tillåter inte skrivning i /etc. `ctf-status`: U7.3 Zonvakten LÖST 2026-11-17 |
| P11 | Policyn utgår från `sepolicy generate --init` | stämmer | `ls -l ~/zonvakt-pol`: zonvakt.te, .if, .fc, zonvakt.sh och zonvakt_selinux.spec, alla 2026-11-17 11:49 – de filer `sepolicy generate` skapar |
| P12 | `files_manage_etc_files`, `auth_etc_filetrans_shadow` och `corecmd_exec_bin` togs bort | stämmer | `grep` efter de tre i `zonvakt.te`: ingen träff. `corecmd_mmap_bin_files` finns kvar. Att audit2allow föreslog dem syns inte i efterhand |
| P13 | read/write på tcp_socket lades till för hand, dolt av dontaudit | stämmer | `zonvakt.te`: `allow zonvakt_t self:tcp_socket { accept bind create getattr listen read setopt write };` (finns inte i `zonvakt.te.orig`). `sesearch --dontaudit`: `dontaudit domain domain:tcp_socket { read write };`. Själva kraschen syns inte i dag |
| P14 | `corenet_tcp_bind_generic_port` är för bred | stämmer (förtydligat) | `sesearch -A -s zonvakt_t -c tcp_socket -p name_bind`: `port_t`, `unreserved_port_t` och `ephemeral_port_t` (se rättelseloggen) |
| P15 | dontaudit-regler gör att audit-loggen inte visar allt som nekas | stämmer | Samma dontaudit-rad som P13 |
| P16 | Före: curl gav 403, AVC `getattr` på `var_t` | ogrundat | Ingen utdata från före åtgärden finns sparad. `ausearch` kräver sudo och kördes inte |
| P17 | Märkt med `semanage fcontext` + `restorecon`, inte `chcon` | stämmer | `matchpathcon /srv/zonwebb/kvitto.txt`: `httpd_sys_content_t`. matchpathcon läser fcontext-reglerna, inte filen, så en bestående regel finns. `chcon` hade inte ändrat matchpathcon |
| P18 | `/srv/zonwebb` har `httpd_sys_content_t` som tål relabel | stämmer | `ls -Z /srv/zonwebb/kvitto.txt` och `ls -Zd /srv/zonwebb`: `httpd_sys_content_t`. `matchpathcon`: samma. Skriptet rad 5: GÄLLER |
| P19 | `curl` mot `/zon/kvitto.txt` ger 200 är inte verifierat | fel | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/zon/kvitto.txt`: 200 (se rättelseloggen) |
| P20 | Kedjan in har policy drop | stämmer | `/etc/nftables/zon.nft` rad 19: `type filter hook input priority 0; policy drop;`. `systemctl is-enabled nftables`: enabled, `is-active`: active |
| P21 | ctf till tcp/80 och tcp/7524 lades till som D8 och D9 | fel (delvis) | `grep -n dport /etc/nftables/zon.nft`: rad 25 `ip saddr $CTF tcp dport 80 accept comment "U7.2 ctf hämtar kvittot"`, rad 26 `… tcp dport 7524 accept comment "D9 …"`. Ingen rad heter D8 (se rättelseloggen) |
| P22 | D8 och D9 i zon.nft och i aktiva brandväggen är inte verifierat | fel (delvis) | zon.nft: se P21. Den aktiva brandväggen (`nft list`) kräver sudo och kontrollerades inte. `ss -tln`: lyssnar på 0.0.0.0:80 och 0.0.0.0:7524 |
| P23 | Skriptet: fem GÄLLER, felkod 0 | stämmer | `/usr/local/bin/verifiera-hardning; echo "felkod: $?"` 2026-11-25: fem GÄLLER, felkod 0 |
| P24 | Felkod 0 täcker bara skriptets fem kontroller | stämmer | Skriptet i repot har samma sha256 som `/usr/local/bin/verifiera-hardning` (fc33b5e6…). Det kontrollerar getenforce, config, domän, permissiv och fcontext – inte hej/overtrad, curl eller brandväggen |

## Rättelselogg

| Nr | Påstående (kort) | Dom | Kommando som avgjorde | Faktiskt utfall | Feltyp | Ändrat till |
|---|---|---|---|---|---|---|
| P4 | "inte prövats med en omstart" | fel | `uptime -s`, `sestatus`, `ctf-status` | Start 2026-11-17 12:52:25, enforcing efter starten, U7.5 LÖST | Ogrundat – omstarten fanns inte i underlaget | Servern startades om 2026-11-17 och står i enforcing efter omstarten. U7.5 godkänd |
| P5 | "nekas och loggas som AVC" | fel (delvis) | `sesearch --dontaudit -s domain -t domain -c tcp_socket` | `dontaudit domain domain:tcp_socket { read write };` | Överdrift i eget underlag (härdningslistan rad 1) | Otillåtna åtgärder nekas. De flesta loggas som AVC, men nekanden som täcks av en dontaudit-regel loggas inte |
| P14 | "vilken oreserverad port som helst" | stämmer (förtydligat) | `sesearch -A -s zonvakt_t -c tcp_socket -p name_bind` | `port_t`, `unreserved_port_t`, `ephemeral_port_t` | Ogrundat i underlaget – omfånget var för smalt beskrivet | zonvakt_t får binda generella porttyper (port_t, unreserved_port_t, ephemeral_port_t). En egen porttyp för 7524 (U7.6) är inte gjord |
| P19 | "curl 200 inte verifierat" | fel | `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/zon/kvitto.txt` | 200 | Ogrundat – curl-utdatan fanns inte i underlaget | httpd serverar `/zon/kvitto.txt` med 200 i enforcing (2026-11-25) |
| P21 | "D8 och D9" | fel (delvis) | `grep -n dport /etc/nftables/zon.nft` | tcp/80 har kommentaren "U7.2 ctf hämtar kvittot", tcp/7524 har "D9" | Fel i eget underlag (härdningslistan rad 4) | ctf till tcp/80 (kommentar "U7.2") och tcp/7524 (D9) finns i zon.nft. Raden för tcp/80 saknar D-nummer |
| P22 | "D8 och D9 inte verifierat" | fel (delvis) | `grep -n dport /etc/nftables/zon.nft`, `ss -tln` | Reglerna finns i filen, portarna lyssnar. Aktiva regler ej lästa (kräver sudo) | Ogrundat i underlaget | Reglerna finns i zon.nft. Att de är laddade i den aktiva brandväggen är inte kontrollerat (`sudo nft list chain inet zon in`) |

## Luckorna i AI-utkastet – vad jag gjorde med dem

| Lucka | Bedömning |
|---|---|
| 1. hej/overtrad saknas | Inte kört 2026-11-25. Policyn saknar regler för skrivning i /etc (P10). U7.3 godkänd 2026-11-17 |
| 2. curl saknas | Kontrollerat – 200 (P19) |
| 3. Paketfiltret overifierat | zon.nft läst (P20–P22). Aktiva regler kräver sudo – inte kontrollerat |
| 4. Flödestabellen saknas | Finns i repot: `docs/vecka_03/flodestabell.md`. Adresserna matades medvetet inte in |
| 5. Skriptets källkod saknas | I repot: [verifiera-hardning](verifiera-hardning), samma sha256 som på servern (P24) |
| 6. Ingen omstart belagd | Fel i utkastet – se P4 |
| 7. `/etc/zonvakt-otillaten` kvar? | `ls -l`: No such file or directory |
| 8. .te/.fc saknas | I repot: [zonvakt.te](zonvakt.te) och [zonvakt.fc](zonvakt.fc), samma sha256 som i `~/zonvakt-pol` på servern |
| 9. AVC och ZON-IN-DROP bara som text | `ausearch` kräver sudo – inte kontrollerat 2026-11-25 |
| 10. Ingen plan för generell portbindning | Stämmer. U7.6 (egen porttyp) är inte löst enligt `ctf-status` (P14) |
| 11. OS bara från beskrivningen | Kontrollerat – se P1 |

**Att rätta i härdningslistan:** rad 4 säger "D8 och D9" (zon.nft har ingen D8, se P21) och rad 1 "loggas som AVC" (gäller inte dontaudit, se P5). Loggregeln i zon.nft har dessutom `limit rate 10/minute`, så "allt annat droppas och loggas" stämmer inte helt – nekandena loggas högst 10 per minut.
