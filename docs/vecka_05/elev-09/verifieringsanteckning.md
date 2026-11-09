# Verifieringsanteckning – vecka 5 (elev-09)

Insamling till loggservern över TLS (port 6514), verifierad med loggsök på jump. Konfiguration: 90-logg.conf.

| Identifierare | Ca tid (UTC) | Värdnamn | Källa | Söksträng | Hittad centralt? | Avvikelse? |
|---|---|---|---|---|---|---|
| spar1e455f23 | 5 nov 07:17 | elev-09 | logger / sparbarhet (U5.1) | spar1e455f23 | Ja, över TLS | Nej |
| sparea6a1e88 | 5 nov 07:22 | elev-09 | logger / kotest (U5.2) | sparea6a1e88 | Ja, 158 s senare (kön höll) | Nej, väntad fördröjning |
| spard6be8dbe | 5 nov 07:35 | elev-09 | auditd / root-cmd (U5.3) | spard6be8dbe | Ja, auid=1000 | Nej |
| – | 9 nov 07:40 | elev-09 | sshd (autentisering) | sshd | Ja, över TLS | Nej |
| – | 9 nov 07:43 | elev-09 | kernel / ZON-IN-DROP (brandvägg) | ZON | Ja, över TLS | Kommer även som KLARTEXT på 514 (gammal 60-brandvagg.conf) – dubblett |
| – | löpande | elev-09 | systemd (system) | systemd | Ja, över TLS | Nej |
| – | – | elev-09 | CROND (cron) | CROND | Nej – medvetet | Struken i urvalet, utesluten med cron.none |

## Avvikelser
- Brandväggsloggen (ZON) kommer fram både som KLARTEXT på 514 (gamla konfigen från vecka 4) och som TLS på 6514. TLS-kopian uppfyller skyddad transport; klartext-kopian är en dubblett. Kan tas bort genom att inaktivera 60-brandvagg.conf.
- cron skickas inte centralt – utesluten med cron.none, i linje med att cron är struken i urvalet.