# Fem frågor och urval – elev-09 (vecka 5)

## Frågor

| Fråga | Källor som krävs | Går att besvara idag? |
|---|---|---|
| 1. Vem loggade in på elev-kontona mellan kl 08 och 17, och kom de in eller nekades de? | /var/log/secure | Ja – secure loggar lokalt och skickas centralt över TLS |
| 2. Vilken adress blev blockerad av brandväggen, mot vilken port, och när? | Brandväggslogg (ZON, journalctl -k / messages) | Ja – finns lokalt och skickas centralt över TLS |
| 3. Vem körde ett kommando som root på elev-09, och när? | /var/log/audit/audit.log (auid) | Ja – auditd skickar posterna centralt sedan U5.3; auid visar vem |
| 4. Vilka paket installerades eller uppdaterades på elev-09, när – och sticker något ut som ingen godkänt? | /var/log/dnf.rpm.log | Ja lokalt, men skickas inte centralt – dnf.rpm.log är en egen fil, inte syslog |
| 5. Vilket fel uppstod eller vilken tjänst kraschade på elev-09, och när? | /var/log/messages | Ja – systemloggen loggar lokalt och skickas centralt över TLS |

## Strukna källor
- cron – stryks, för ingen av mina frågor handlar om schemalagda jobb. Loggen visar bara rutinjobb som körs automatiskt, och det var inget jag behövde fastställa.