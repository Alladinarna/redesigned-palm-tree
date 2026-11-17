# Nedbrytning av händelser – elev-24

**Mätfönster:** normaltrafik 2026-11-11 07:06–07:36 UTC (0,5 h, `inmatat/elev-24/normal.log`). Verifierat fönster 2026-10-27 12:40 UTC – 2026-11-17 13:41 UTC (≈ 505 h, min egen ström `elev-24/syslog.log`).

Alla monitorer söker de senaste **5 min**, körs varje minut och avgränsar på **elev-24** (`location`).

## Översikt

| Händelse | Loggkälla | Filter | Faktiska värden | Gränsfall |
|---|---|---|---|---|
| 1. Brute force mot SSH | sshd-session, wazuh-alerts-* | location elev-24, rule.id 5710/5712/5760/5763, ≥5 på 5 min | 172.20.1.10, test5, backup25, admin77 m.fl., 2026-11-11 08:33 UTC | Enstaka fel lösenord på befintligt konto (enstaka 5760) |
| 2. Zonöverträdelse | kernel (nftables), wazuh-archives-* | location elev-24, full_log "ZON-IN-DROP" | 172.20.1.2 till port 8080, IN=eth1, 2026-11-11 08:33 UTC | ZON-UT-DROP (egen utgående trafik som stoppas) |
| 3. Root-kommando | auditd (audisp-syslog), wazuh-archives-* | location elev-24, full_log "type=SYSCALL" och "success=yes" och nyckeln `root-cmd` **eller** `rootcmd` | auid=1000 (student), euid=0, syscall 59 (execve), exe=/usr/bin/sudo, 2026-11-11 08:18 UTC | CONFIG_CHANGE med samma nyckel när auditreglerna laddas om |
| 4. Nytt användarkonto | useradd, wazuh-alerts-* | location elev-24, rule.id 5902, inte data.shell *nologin* | test24, uid 1001, /bin/bash, 2026-11-17 13:40 UTC | Systemkonto från dnf, `/sbin/nologin` (filtreras bort på shell) |

---

## Kommentarer

### 1. Brute force mot SSH

Vi letar efter många misslyckade SSH-inloggningar mot elev-24. Raderna skrivs av `sshd-session`. Wazuh har egna regler: 5710/5712 för påhittade användare och 5760/5763 för konton som finns. Händelserna finns i `wazuh-alerts-*`. Detektionen slår till först vid minst 5 försök inom 5 minuter.

- **Larmet betyder:** minst 5 misslyckade inloggningsförsök inom 5 minuter, från en eller flera adresser, vilket tyder på ett brute force-försök.
- **Riktig träff:** ctf-servern 172.20.1.10 provade 12 påhittade användarnamn (test5, backup25, admin77, oracle18 …) den 11/11 kl. 08:33:23–08:33:30 UTC (U6.2). 11 × 5710 och 1 × 5712.
- **Ska inte larma:** någon som skriver fel lösenord en eller ett par gånger på ett konto som finns (enstaka 5760).
- **Brus, normaltrafik:** 91 träffar på 0,5 h från 9 olika adresser (83 × 5710, 6 × 5760, 1 × 5712, 1 × 5763). Fyra av sex femminutersfönster hade 5 eller fler träffar (07:10: 35, 07:15: 20, 07:20: 10, 07:30: 23), så monitorn hade larmat där – falsklarm från normaltrafiken.
- **Brus, verifierat fönster:** 12 träffar på 505 h (≈ 0,02/h). Alla är U6.2.
- **Falsklarmsrisk:** tröskeln räknar alla adresser tillsammans. Det fångar distribuerade angrepp, men normaltrafiken visar att flera källor med några försök var räcker för att passera tröskeln. En tröskel per data.srcip hade gett färre falsklarm men missat distribuerade angrepp.

### 2. Zonöverträdelse

Vi letar efter trafik som brandväggen (nftables) på elev-24 stoppar på väg **in**. Det är kärnan som loggar, därför står det `kernel` som program. Ingen standardregel larmar, så raderna finns bara i `wazuh-archives-*`. Vi filtrerar på loggprefixet `ZON-IN-DROP` som står sist i kedjan in i `zon.nft`.

- **Larmet betyder:** någon har försökt nå en port på elev-24 som flödestabellen inte tillåter, och brandväggen stoppade det. Det kan vara kartläggning inför ett angrepp, en felkonfigurerad tjänst eller ett eget test.
- **Riktig träff:** 172.20.1.2 (jump) försökte nå port 80 via eth1 den 28/10 kl. 07:44 UTC.
- **Framkallad (vecka 6):** jump 172.20.1.2 mot port 8080 via eth1 den 11/11 kl. 08:33:20 UTC.
- **Ska inte larma:** `ZON-UT-DROP`, alltså egen utgående trafik som stoppas. Det är en annan händelse och söks inte här.
- **Brus, normaltrafik:** 0 träffar på 0,5 h – inga falsklarm.
- **Brus, verifierat fönster:** 316 träffar på 505 h (≈ 0,6/h). 271 av dem kom från internet via eth0 den 27/10 kl. 12:40–13:11 UTC. Efter det finns inga träffar via eth0, och molnbrandväggen (U4.4, 28/10) stoppar sådan trafik innan den når servern. Resten (45) kom via eth1: egna tester från jump mot port 80, 443 och 8080 (37), CTF-kontroller från 172.20.1.203 den 27/10 (2) och ctf-servern 172.20.1.10 mot port 80 och 7524 den 17/11 (6), innan flödena D8 och D9 lades till för U7.2 och U7.3.
- **Falsklarmsrisk:** egna tester från jump och CTF-kontroller larmar likadant som en riktig kartläggning och måste stämmas av mot testloggen. Ett angrepp på en port som är tillåten syns inte här. Utan molnbrandväggen blir bruset från internet stort (271 träffar på en halvtimme).

### 3. Kommando som körs som root

Vi letar efter kommandon som en **inloggad person** kör med root-rättigheter (till exempel via sudo). auditd loggar dem och skickar dem vidare via `audisp-syslog`. Ingen standardregel larmar, så de finns bara i `wazuh-archives-*`, och allt ligger i `full_log`. Ett kommando ger flera auditposter, men nyckeln står bara i SYSCALL, så vi räknar bara `type=SYSCALL` med `success=yes`.

- **Larmet betyder:** en inloggad användare har kört ett kommando som root på elev-24 – oftast administration, men det kan vara en angripare som tagit över ett konto.
- **Riktig träff:** student (auid 1000) körde sudo som root (euid 0, execve) den 11/11 kl. 08:18 UTC.
- **Ska inte larma:** när auditreglerna laddas om loggas `CONFIG_CHANGE` med samma nyckel. Det är inget kommando, och därför filtrerar vi på `type=SYSCALL`. `success=no` (1 träff) räknas inte heller.
- **Falskt negativt (hittat 2026-11-17):** nyckeln bytte namn från `root-cmd` till `rootcmd` den 7/11 kl. 05:16 UTC, när auditreglerna laddades om. Ett filter på bara `root-cmd` hade missat alla 359 root-kommandon efter det, alltså hela vecka 6 och 7. Filtret söker därför på båda nycklarna.
- **Brus, normaltrafik:** 0 träffar på 0,5 h.
- **Brus, verifierat fönster:** 883 träffar på 505 h (≈ 1,7/h): 524 med `root-cmd` (2/11–7/11) och 359 med `rootcmd` (7/11–17/11). Allt är egen administration som student, till exempel nft, ss, journalctl och SELinux-arbetet i vecka 7 (323 träffar den 17/11). Det ger högst falsklarmsrisk av de fyra.
- **Falsklarmsrisk:** allt administrativt sudo-arbete larmar likadant som en angripare med ett stulet konto. Att undanta vanliga kommandon minskar bruset men skapar en blind fläck.

### 4. Nytt användarkonto

Vi letar efter att någon skapar ett konto – en angripare gör det för att kunna komma tillbaka senare (persistence, ATT&CK T1136). Raderna skrivs av `useradd`. Wazuh har en egen regel (5902 "New user added to the system"), så händelsen finns i `wazuh-alerts-*`.

- **Larmet betyder:** någon har skapat ett konto med inloggningsbar shell på elev-24 – det kan vara en bakdörr.
- **Riktig träff:** test24 skapades med uid 1001 och `/bin/bash` den 17/11 kl. 13:40:55 UTC (`sudo useradd -m test24`). Kontot togs bort två sekunder senare med `sudo userdel -r test24` (regel 5903, 13:40:57 UTC).
- **Samma kommando ger fler larm:** 5402 (sudo till root) och 5901 (ny grupp) kom samtidigt. Vi använder bara 5902, eftersom 5901 alltid kommer tillsammans med den. useradd syns också som root-kommando i händelse 3 (nyckeln `rootcmd`).
- **Ska inte larma:** systemkonton som skapas när ett paket installeras med dnf (`/sbin/nologin`). De filtreras bort på shell, inte på uid.
- **Brus, normaltrafik:** 0 träffar på 0,5 h – inga falsklarm.
- **Brus, verifierat fönster:** 1 träff på 505 h (≈ 0,002/h), det egna testet med test24.
- **Falsklarmsrisk:** legitim kontoadministration larmar likadant. Samma `sudo useradd` ger också en träff i händelse 3.
