# Nedbrytning av händelser – elev-46
 
**Mätfönster:** normaltrafik 2026-11-11 07:06–07:37 UTC (0,5 h). Verifierat fönster 2026-10-28 11:00 UTC – 2026-11-12 07:42 UTC (≈ 357 h).
 
## Översikt
 
| Händelse | Loggkälla | Filter | Faktiska värden | Gränsfall |
|---|---|---|---|---|
| 1. Brute force mot SSH | sshd-session, wazuh-alerts-* | location elev-46, rule.id 5710/5712, ≥5 på 5 min | 172.20.1.10, admin97 m.fl., 2026-11-10 10:10 UTC | Enstaka feltryckning, fel lösenord på befintligt konto (5760) |
| 2. Zonöverträdelse | kernel (nftables), wazuh-archives-* | location elev-46, data.action ZON-IN-DROP | 172.20.1.2 till port 80, IN=eth1, 2026-11-02 08:37 UTC | ZON-UT-DROP från port 80 med ACK/FIN (svarstrafik) |
| 3. Root-kommando | auditd (audisp-syslog), wazuh-archives-* | location elev-46, audisp-syslog, full_log "root-cmd" och "type=SYSCALL" | auid=1000 (student), euid=0, exe=/usr/sbin/nft, 2026-11-09 07:29 UTC | CONFIG_CHANGE op=add_rule med samma nyckel, 2026-11-09 07:26 UTC |
| 4. Nytt användarkonto | useradd, wazuh-alerts-* | location elev-46, rule.id 5902, inte data.shell *nologin* | test46, uid 1001, /bin/bash, 2026-11-11 08:38 UTC | Systemkonto från dnf, uid under 1000, /sbin/nologin (filtreras bort på shell) |
 
---
 
## Kommentarer
 
### 1. Brute force mot SSH
 
Vi letar efter många misslyckade SSH-inloggningar mot elev-46. Raderna skrivs av programmet `sshd-session`. Wazuh har egna regler för detta (5710 och 5712), så händelserna finns i `wazuh-alerts-*`. Detektionen ska slå till först vid minst 5 försök inom 5 minuter.
 
- **Larmet betyder:** minst 5 misslyckade inloggningsförsök inom 5 minuter, från en eller flera adresser, vilket tyder på ett brute force-försök.
- **Riktig träff:** ctf-servern 172.20.1.10 provade admin97 och andra påhittade användarnamn den 10/11 kl. 10:10 UTC (U6.2).
- **Ska inte larma:** någon som skriver fel lösenord en gång på ett konto som finns. Wazuh ger det regel 5760, och det är ett vanligt misstag, inget angrepp.
- **Brus, normaltrafik:** 10 träffar på 0,5 h (10 försök från olika adresser samma sekund) – monitorn hade larmat en gång, ett falsklarm.
- **Brus, verifierat fönster:** 22 träffar på 357 h (≈ 0,06/h). Alla förklarade: U6.2 och normaltrafiken.
- **Falsklarmsrisk:** tröskeln räknar alla adresser tillsammans. Det fångar distribuerade angrepp men larmar också på misslyckade försök från flera källor samtidigt. En tröskel per data.srcip hade gett färre falsklarm men missat distribuerade angrepp.
### 2. Zonöverträdelse
 
Vi letar efter trafik som vår brandvägg (nftables) stoppar på väg **in**. Det är kärnan som loggar, därför står det `kernel` som program. Ingen standardregel larmar på raderna, så de finns bara i `wazuh-archives-*`. Vi filtrerar på loggprefixet `ZON-IN-DROP` som vi själva satte i `zon.nft`.
 
- **Larmet betyder:** någon har försökt nå en port på elev-46 som brandväggen har stoppat. Det kan vara kartläggning inför ett angrepp eller en felkonfigurerad tjänst.
- **Riktig träff:** 172.20.1.2 försökte nå port 80 via eth1 den 2/11 kl. 08:37 UTC.
- **Ska inte larma:** `ZON-UT-DROP` med ACK/FIN från port 80. Det är svar på en anslutning som redan stängts, alltså svarstrafik och inget angrepp.
- **Falsklarmsrisk:** våra egna testkörningar från jump och CTF-kontrollerna från ctf-servern larmar likadant som ett riktigt försök. De måste stämmas av mot testloggen och kontrollernas tider.
- **Framkallad:** paket från jump mot 172.20.1.146:80, 2026-11-11 11:44:03 UTC. Monitorn larmade 11:44 och avslutades 11:49 UTC (fönster 5 min).
- **Brus, normaltrafik:** 0 träffar på 0,5 h – inga falsklarm.
- **Brus, verifierat fönster:** 33 träffar på 357 h (≈ 0,09/h). Alla förklarade: egna tester från jump mot port 80 och CTF-kontroller från ctf-servern (172.20.1.10 och 172.20.1.203, U4.1/U4.2) mot slumpade portar.
  
### 3. Kommando som körs som root
 
Vi letar efter kommandon som en **inloggad person** kör med root-rättigheter (till exempel via sudo). auditd loggar dem med nyckeln `root-cmd` och skickar dem vidare via `audisp-syslog`. Ingen standardregel larmar, så de finns bara i `wazuh-archives-*`. Wazuh tolkar inte auditposterna här, så allt ligger i `full_log`.
 
Ett kommando ger flera auditposter (SYSCALL, EXECVE, PROCTITLE m.fl.). Nyckeln står bara i SYSCALL, så vi räknar bara SYSCALL – då blir det en träff per kommando.
 
- **Larmet betyder:** en inloggad användare har kört ett kommando som root på elev-46 – oftast administration, men kan vara en angripare som tagit över ett konto.
- **Riktig träff:** student (auid 1000) körde `nft` som root den 9/11 kl. 07:29 UTC.
- **Ska inte larma:** när auditreglerna laddas om loggas `CONFIG_CHANGE op=add_rule` med samma nyckel. Det är inget kommando, och därför filtrerar vi på `type=SYSCALL`.
- **Brus, normaltrafik:** 5 träffar på 0,5 h, alla egen administration (student körde nft som root 07:35 UTC) – monitorn hade larmat en gång, ett falsklarm.
- **Brus, verifierat fönster:** 230 träffar på 357 h (≈ 0,6/h). Nästan allt egen administration – högst falsklarmsrisk av de fyra.
- **Falsklarmsrisk:** allt administrativt arbete med sudo larmar likadant som en angripare med ett stulet konto. Att undanta vanliga kommandon minskar bruset men skapar en blind fläck.
### 4. Nytt användarkonto
 
Vi letar efter att någon skapar ett konto – en angripare gör det för att kunna komma tillbaka senare (persistence, ATT&CK T1136). Raderna skrivs av `useradd`. Wazuh har en egen regel (5902 "New user added to the system"), så händelsen finns i `wazuh-alerts-*`.
 
Ett `sudo useradd` ger tre larm: 5902 (nytt konto), 5901 (ny grupp) och 5402 (sudo till root). Vi använder bara 5902, eftersom 5901 alltid kommer tillsammans med den. Samma kommando ger också en träff i händelse 3.
 
- **Larmet betyder:** någon har skapat ett konto med inloggningsbar shell på elev-46 – kan vara en bakdörr för att komma tillbaka (persistence).
- **Riktig träff:** test46 skapades med uid 1001 och `/bin/bash` den 11/11 kl. 08:38 UTC. Kontot är borttaget efteråt.
- **Ska inte larma:** systemkonton som skapas när ett paket installeras med dnf (uid under 1000, `/sbin/nologin`). De filtreras bort på shell, inte på uid.
- **Filter:** `location: *elev-46* and rule.id: 5902 and not data.shell: *nologin*`. Wazuh lagrar shell med ett kommatecken på slutet (`/bin/bash,`), därför jokertecken.
- **Att tänka på:** regel 5902 larmar även för systemkonton (verifierat med `useradd -r test46r`: uid 994, `/bin/bash`, 2026-11-11 09:01 UTC). Att filtrera bort uid under 1000 hade alltså dolt ett konto som en angripare skapat med `-r`, och `useradd -o -u 0` ger dessutom ett andra root-konto. Därför filtrerar vi på shell.
- **Brus, normaltrafik:** 0 träffar på 0,5 h – inga falsklarm.
- **Brus, verifierat fönster:** 2 träffar på 357 h (≈ 0,006/h). Båda egna tester (test46, test46r).
- **Falsklarmsrisk:** legitim kontoadministration larmar likadant; systemkonton från dnf filtreras bort på shell.
