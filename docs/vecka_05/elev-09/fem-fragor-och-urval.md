# Fem frågor och urval – elev-09 (vecka 5)

## Frågor
1. Vem loggade in på elev-kontona mellan kl 08 och 17, och kom de in eller nekades de? → /var/log/secure
2. Vilken adress blev blockerad av brandväggen, mot vilken port, och när? → ZON-DROP (journalctl -k)
3. Vem körde ett kommando som root på elev-09, och när? → /var/log/audit/audit.log (auid)
4. Vilka paket installerades eller uppdaterades på elev-09, när – och sticker något ut som ingen godkänt? → /var/log/dnf.rpm.log
5. Vilket fel uppstod eller vilken tjänst kraschade på elev-09, och när? → /var/log/messages

## Strukna källor
- cron – stryks, för ingen av mina frågor handlar om schemalagda jobb. Loggen visar bara rutinjobb som körs automatiskt, och det var inget jag behövde fastställa.