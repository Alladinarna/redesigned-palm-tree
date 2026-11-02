# Fem frågor och urval – vecka 5

Workshop 1, del 2. Urvalet styrs av vilka frågor uppdragsgivaren måste kunna besvara i efterhand, inte av hur mycket som går att samla in (NIST SP 800-92 4.2). Varje fråga har ett tidsspann, ett subjekt och något som ska fastställas.

> **Utkast** (2/11), som teamet granskar och justerar i workshop 1. Källorna kommer från [loggkällekartan](loggkallekarta.md).

## Frågor

| Id | Fråga (tidsspann, subjekt, vad som ska fastställas) | Källor som krävs | Går att besvara idag (2/11)? |
|---|---|---|---|
| U1 | Vem loggade in via SSH på någon av teamets servrar mellan kl. 02 och 04 UTC en given natt, från vilken adress och med vilken nyckel? | sshd i authpriv (`/var/log/secure`), centralt på log | Bara lokalt. `secure` skickas inte till log (vecka 4 skickade bara `kern.*`) |
| U2 | Vilka kommandon kördes med root-behörighet på teamets servrar under det senaste dygnet, och av vilken inloggad person (auid)? | auditd (EXECVE och SYSCALL med samma `msg=audit(TID:SERIENUMMER)`), sudo i authpriv | Nej. Det finns ingen auditregel för root-kommandon och syslog-pluginet är inte installerat (`rpm -q audispd-plugins`) |
| U3 | Vilken trafik från DMZ (elev-46) eller Klientzonen (elev-09) försökte under den senaste veckan nå zoner som flödestabellen inte tillåter, och på vilka portar? | Paketfiltrets loggrader `ZON-IN-DROP` / `ZON-UT-DROP` (kern) från alla fyra servrar | Delvis. Raderna skickas sedan vecka 4, men i klartext på tcp/514 |
| U4 | Slutade någon av teamets servrar att skicka loggar till loggservern under incidentfönstret, och i så fall när och hur länge? | Mottagningstiden på log (`loggsök`), rsyslogs egen logg (`journalctl -u rsyslog`), avsändarens tidsstämpel | Delvis. Mottagningstiden finns centralt, men rsyslogs egen logg finns bara i journalen, som försvinner vid omstart |
| U5 | Gick klockan rätt på alla fyra servrar under incidentfönstret, så att händelser från olika servrar kan läggas i en tidslinje? | chronyd i systemloggen, RFC 5424-tidsstämpel med delsekunder och tidszon i den vidarebefordrade raden | Delvis. chrony synkar mot ntp.hetzner.com och tidszonen är UTC, men vidarebefordran i vecka 4 använder inte RFC 5424-format |

U2 och U5 är också krav i MCFFS 2026:11, 4 kap. 21–23 §§ (säkerhetsloggning, analys och robust och korrekt tid), och 4 kap. 25 § kräver att säkerhetsloggar krypteras vid överföring.

## Urval som skickas till log från vecka 5

Det här är det som [90-logg.conf](logginsamling/90-logg.conf) skickar (`*.info;mail.none;cron.none`):

| Källa | Behövs för |
|---|---|
| authpriv: sshd och sudo | U1, U2 |
| auditd via syslog-pluginet (facility user) | U2 |
| kern: paketfiltret `ZON-*` | U3 |
| Systemloggen: rsyslog, chronyd, systemd | U4, U5 |

## Strukna källor och skäl

| Struken källa | Varför ingen fråga behöver den |
|---|---|
| cron (`/var/log/cron`) | Ingen av frågorna gäller schemalagda jobb. Om någon lägger in ett cron-jobb som root syns det ändå i U2 (auditd) |
| mail och spooler | Filerna är tomma och det finns ingen e-posttjänst på servrarna |
| cloud-init | Skrivs bara när servern skapas. Stoppas redan av `21-cloudinit.conf` (`& stop`) |
| dnf-loggarna | Paketinstallationer görs med sudo och fångas därför av U2 (auditd och sudo) |
| lastlog, wtmp och btmp | Binära filer som innehåller samma inloggningar som sshd i `secure` (U1) |
| httpd: access_log och error_log | **Skjuts upp, men stryks inte.** Ingen av de fem frågorna gäller webbtrafik idag. Tas upp igen inför detektionerna (vecka 6) och incidenten (vecka 8). Skulle kräva imfile |
