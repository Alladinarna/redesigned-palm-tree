# Nedbrytning av händelser – elev-46
 
## Översikt
 
| Händelse | Loggkälla | Filter | Faktiska värden | Gränsfall |
|---|---|---|---|---|
| 1. Brute force mot SSH | sshd-session, wazuh-alerts-* | location elev-46, rule.id 5710,5712, 5760, 5763,  ≥5 på 5 min | 172.20.1.10, admin97 m.fl., 2026-11-10 10:10 UTC | Enstaka feltryckning, fel lösenord på befintligt konto (5760) |
| 2. Zonöverträdelse | kernel (nftables), wazuh-archives-* | location elev-46, data.action ZON-IN-DROP | 172.20.1.2 till port 80, IN=eth1, 2026-11-02 08:37 UTC | ZON-UT-DROP från port 80 med ACK/FIN (svarstrafik) |
| 3. Root-kommando | auditd (audisp-syslog), wazuh-archives-* | location elev-46, audisp-syslog, full_log "root-cmd" och "type=SYSCALL" | auid=1000 (student), euid=0, exe=/usr/sbin/nft, 2026-11-09 07:29 UTC | CONFIG_CHANGE op=add_rule med samma nyckel, 2026-11-09 07:26 UTC |
| 4. Nytt användarkonto | useradd, wazuh-alerts-* | location elev-46, rule.id 5902, inte data.shell *nologin* | test46, uid 1001, /bin/bash, 2026-11-11 08:38 UTC | Systemkonto från dnf, uid under 1000, /sbin/nologin (filtreras bort på shell) |
 
---
 
## Kommentarer
 
### 1. Brute force mot SSH
 
Vi letar efter många misslyckade SSH-inloggningar mot elev-46. Raderna skrivs av programmet `sshd-session`. Wazuh har egna regler för detta (5710 och 5712), så händelserna finns i `wazuh-alerts-*`. Detektionen ska slå till först vid minst 5 försök inom 5 minuter.
 
- **Riktig träff:** ctf-servern 172.20.1.10 provade admin97 och andra påhittade användarnamn den 10/11 kl. 10:10 UTC (U6.2).
- **Ska inte larma:** någon som skriver fel lösenord en gång på ett konto som finns. Wazuh ger det regel 5760, och det är ett vanligt misstag, inget angrepp.
- - **Falskt negativt (hittat 2026-11-12):** 24 felaktiga lösenord mot det befintliga kontot student på elev-09 (5760/5763, 08:33–08:43 UTC) gav inget larm, eftersom monitorn bara räknade 5710/5712 (påhittade användare). Monitorn utökad med 5760 och 5763.

### 2. Zonöverträdelse
 
Vi letar efter trafik som vår brandvägg (nftables) stoppar på väg **in**. Det är kärnan som loggar, därför står det `kernel` som program. Ingen standardregel larmar på raderna, så de finns bara i `wazuh-archives-*`. Vi filtrerar på loggprefixet `ZON-IN-DROP` som vi själva satte i `zon.nft`.
 
- **Riktig träff:** 172.20.1.2 försökte nå port 80 via eth1 den 2/11 kl. 08:37 UTC.
- **Ska inte larma:** `ZON-UT-DROP` med ACK/FIN från port 80. Det är svar på en anslutning som redan stängts, alltså svarstrafik och inget angrepp.
- **Falsklarmsrisk:** våra egna testkörningar från jump larmar likadant som ett riktigt försök, eftersom källa och port är desamma. De måste stämmas av mot testloggen.
- **Framkallad:** paket från jump mot 172.20.1.146:80, 2026-11-11 11:44:03 UTC. Monitorn larmade 11:44 och avslutades 11:49 UTC (fönster 5 min).
### 3. Kommando som körs som root
 
Vi letar efter kommandon som en **inloggad person** kör med root-rättigheter (till exempel via sudo). auditd loggar dem med nyckeln `root-cmd` och skickar dem vidare via `audisp-syslog`. Ingen standardregel larmar, så de finns bara i `wazuh-archives-*`. Wazuh tolkar inte auditposterna här, så allt ligger i `full_log`.
 
Ett kommando ger flera auditposter (SYSCALL, EXECVE, PROCTITLE m.fl.). Nyckeln står bara i SYSCALL, så vi räknar bara SYSCALL – då blir det en träff per kommando.
 
- **Riktig träff:** student (auid 1000) körde `nft` som root den 9/11 kl. 07:29 UTC.
- **Ska inte larma:** när auditreglerna laddas om loggas `CONFIG_CHANGE op=add_rule` med samma nyckel. Det är inget kommando, och därför filtrerar vi på `type=SYSCALL`.
### 4. Nytt användarkonto
 
Vi letar efter att någon skapar ett konto – en angripare gör det för att kunna komma tillbaka senare (persistence, ATT&CK T1136). Raderna skrivs av `useradd`. Wazuh har en egen regel (5902 "New user added to the system"), så händelsen finns i `wazuh-alerts-*`.
 
Ett `sudo useradd` ger tre larm: 5902 (nytt konto), 5901 (ny grupp) och 5402 (sudo till root). Vi använder bara 5902, eftersom 5901 alltid kommer tillsammans med den. Samma kommando ger också en träff i händelse 3.
 
- **Riktig träff:** test46 skapades med uid 1001 och `/bin/bash` den 11/11 kl. 08:38 UTC. Kontot är borttaget efteråt.
- **Ska inte larma:** systemkonton som skapas när ett paket installeras med dnf (uid under 1000, `/sbin/nologin`). De filtreras bort på shell, inte på uid.
- **Filter:** `location: *elev-46* and rule.id: 5902 and not data.shell: *nologin*`. Wazuh lagrar shell med ett kommatecken på slutet (`/bin/bash,`), därför jokertecken.
- **Att tänka på:** regel 5902 larmar även för systemkonton (verifierat med `useradd -r test46r`: uid 994, `/bin/bash`, 2026-11-11 09:01 UTC). Att filtrera bort uid under 1000 hade alltså dolt ett konto som en angripare skapat med `-r`, och `useradd -o -u 0` ger dessutom ett andra root-konto. Därför filtrerar vi på shell.
