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
