# Härdning av elev-38 (vecka 7)

Server: elev-38, Databaszonen (172.20.1.138 på eth1, 10.40.1.162 på eth2), Rocky Linux 9.
Genomfört och verifierat 2026-11-23 av Naima. Alla tider i UTC.
Verifieringsskript: `/usr/local/bin/verifiera-hardning` (körs med `sudo`, felkod 0 = allt gäller). Det överlevde en omstart (U7.5).

## Härdningslista

| Nr | Åtgärd | Motivering – varför just här | Förväntad effekt | Hur den verifierades | Skript? |
|---|---|---|---|---|---|
| 1 | SELinux i Enforcing, både nu och efter omstart | Utan MAC skyddar bara filrättigheterna (DAC), och dem går root förbi. Om läget bara sätts med `setenforce` försvinner det vid omstart. | Policyn tvingas alltid, inte bara loggas. | `getenforce` gav `Enforcing`. `grep ^SELINUX= /etc/selinux/config` gav `SELINUX=enforcing`. Samma sak efter omstarten. | ☑ |
| 2 | Tjänsten zonvakt (port 7538) under en egen tvingande policy, domänen `zonvakt_t` | zonvakt kör som root. I `unconfined_service_t` kunde den skriva `/etc/zonvakt-otillaten` (testat med `overtrad`). En vakttjänst har inget att göra i /etc. | `hej` fungerar, men `overtrad` nekas trots att tjänsten är root. | `ps -eZ` visade `zonvakt_t`, och `semanage permissive -l` var tom. `overtrad` gav `nekad: Permission denied`. AVC löpnummer 2536 (06:42:23): `denied { write }` på /etc (`etc_t`), `permissive=0`. Samma rad finns i Wazuh (`wazuh-archives-*`, `comm=zonvakt`, rule.id 100200). | ☑ |
| 3 | Bestående filkontext `httpd_sys_content_t` för `/srv/zonwebb` (`semanage fcontext` + `restorecon`, inte `chcon`) | httpd gav 403 på `/zon/kvitto.txt`. AVC 1859: `httpd_t` nekades `getattr` på `var_t`. `chcon` försvinner vid nästa relabel. | httpd får läsa just den katalogen, och ändringen finns kvar efter en relabel. | `semanage fcontext -l -C` visar regeln. `ls -Zd /srv/zonwebb` ger `httpd_sys_content_t`. `curl http://127.0.0.1/zon/kvitto.txt` gav kvittot, och ctf-servern hämtade sidan (U7.2). | ☑ |
| 4 | Paketfiltret behåller `policy drop`. Bara de två nya flödena från ctf (172.20.1.10 → tcp/80 och tcp/7538) släpps in, före loggregeln `ZON-IN-DROP` | Kontrollerna kräver flödena. Att stänga av filtret hade öppnat allt. Regler efter loggraden hade loggats som stoppade. | Bara ctf når de två portarna. Allt annat nekas och loggas fortfarande. | `nft list chain inet zon in` visar båda reglerna och `policy drop`. `systemctl is-enabled nftables` ger `enabled`. `zon.nft` inkluderas i `/etc/sysconfig/nftables.conf`. | ☑ |

## Policyn för zonvakt

Policyn genererades med `sepolicy generate --init` och kördes först i permissivt läge. Jag läste AVC:erna och granskade förslagen från `audit2allow -R`:

- **Med:** `allow zonvakt_t self:tcp_socket { accept bind create getattr listen read setopt write }`, `corenet_tcp_bind_generic_node`, `corenet_tcp_bind_generic_port`, `corecmd_exec_bin`, `corecmd_mmap_bin_files` (zonvakt är ett Python-skript), `auth_read_passwd_file`, `sssd_read_public_files`, `sssd_search_lib` (bara läsning).
- **Inte med:** `files_manage_etc_files` och `auth_etc_filetrans_shadow`. Det är skrivningen i /etc, alltså det policyn ska stoppa.
- **audit2allow missade** `read` och `write` på uttaget. Efter att jag tagit bort `permissive zonvakt_t;` kraschade tjänsten på `sendall` (PermissionError i journalen). Jag lade till dem själv. Lärdom: audit2allow ser bara det som loggades, så man måste testa.
- **För bred:** `corenet_tcp_bind_generic_port` låter zonvakt binda vilken oreserverad port som helst. Det kan snävas in med en egen porttyp (U7.6, inte gjord).

## AI-stöd

Utkastet till den här filen skrevs av en AI-assistent (Claude) utifrån mina egna kommandoutskrifter från elev-38 och Wazuh den 23/11. Inga lösenord, tokens eller nycklar matades in. Varje påstående i tabellen ska kontrolleras mot servern med kommandot i kolumnen "Hur den verifierades".
