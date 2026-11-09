# Loggkällekarta – elev-09 (vecka 5)

| Källa | Var den läses | Exempelrad från elev-09 | Vilken fråga den svarar på | Rotation / hur långt bakåt | Tidsformat |
|---|---|---|---|---|---|
| Systemlogg | /var/log/messages | Nov 4 07:14:44 elev-09 systemd[9731]: Finished Cleanup of User's Temporary Files and Directories. | Vad har hänt på systemet allmänt? | weekly, rotate 4 → 4 veckor | gammalt syslog (saknar år/tidszon) |
| Autentiseringslogg | /var/log/secure | Nov 4 07:16:02 elev-09 sudo[9787]: pam_unix(sudo:session): session closed for user root | Vem loggade in / körde sudo? | weekly, rotate 4 → 4 veckor | gammalt syslog |
| Paketfiltrets logg | kärnan (journalctl -k) | Oct 29 08:42:31 elev-09 kernel: ZON-IN-DROP IN=eth1 SRC=172.20.1.2 DST=172.20.1.109 DPT=80 SYN | Vilken trafik blockerade brandväggen? | journalen i minnet, ingen filrotation | gammalt syslog |
| Audit-logg | /var/log/audit/audit.log | type=USER_START msg=audit(1793776605.827:918): auid=1000 acct="root" exe="/usr/bin/sudo" AUID="student" | Vem körde ett root-kommando (auid)? | auditd roterar själv (på storlek) | epoch-tid |
| Cron | /var/log/cron | Nov 4 07:01:01 elev-09 CROND[9716]: (root) CMDEND (run-parts /etc/cron.hourly) | Vilka schemalagda jobb kördes? | weekly, rotate 4 → 4 veckor | gammalt syslog |
| Paketlogg | /var/log/dnf.rpm.log | 2026-11-04T05:54:34+0000 INFO --- logging initialized --- | Vilka paket installerades/uppdaterades? | egen rotation (/etc/logrotate.d/dnf) | ISO 8601 (med år och tidszon) |