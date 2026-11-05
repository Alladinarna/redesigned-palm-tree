# Verifieringsanteckning – vecka 5 (elev-46)

Insamling till loggservern över TLS (port 6514), verifierad med `loggsök` på jump den 5 november 2026. Konfiguration: [90-logg.conf](90-logg.conf).

| Identifierare | Ca tid (UTC) | Värdnamn | Källa | Söksträng | Hittad centralt? | Avvikelse? |
|---|---|---|---|---|---|---|
| spar92b56776 | 07:41 | elev-46 | logger / sparbarhet | spar92b56776 | Ja, över TLS | Tidsstämpeln saknar millisekunder |
| spar84922b06 | 08:36 | elev-46 | logger / kotest | spar84922b06 | Ja, 198 s senare (kön höll) | Nej, väntad fördröjning |
| – | 08:02 | elev-46 | sshd (autentisering) | sshd | Ja, över TLS | Nej |
| – | 08:03 | elev-46 | kernel / ZON-UT-DROP (brandvägg) | ZON | Ja, över TLS | Äldre rader finns som KLARTEXT, från före omkopplingen |
| – | 08:01 | elev-46 | CROND (cron) | CROND | Ja, över TLS | Nej |
| – | 07:35 | elev-46 | systemd (system) | systemd | Ja, över TLS | Fördröjda ca 3,5 min medan TLS låg nere, levererade av kön |
| spar38a207e4 | 10:26 | elev-46 | auditd / root-cmd | spar38a207e4 | Ja, auid=1000 | Nej |

## Avvikelser

1. **CA-filen gick först inte att läsa** (`Permission denied`). Den hade flyttats med `mv` från hemkatalogen och behöll SELinux-etiketten `user_home_t`. Löst med `sudo restorecon -v /etc/pki/rsyslog/ca.pem`.
2. **Varningarna `certificate file is not set` och `key file is not set`** gäller elev-46:s eget certifikat, som bara behövs om loggservern ska kontrollera avsändaren. De påverkar inte leveransen.
3. **Brandväggsrader före kl. 07:38** kom fram i klartext på port 514, från den gamla konfigurationen. Alla rader efter omkopplingen kommer via TLS.
