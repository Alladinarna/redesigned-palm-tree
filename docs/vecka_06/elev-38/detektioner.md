# Nedbrytning av händelser – elev-38

**Mätfönster:** normaltrafik 2026-11-11 07:06–07:37 UTC (0,5 h). Verifierat fönster 2026-11-04 23:00 UTC – 2026-11-16 08:14 UTC (≈ 273 h). För brute force mättes det verifierade fönstret till 2026-11-15 19:52 UTC (≈ 261 h).

Alla monitorer söker de senaste 5 minuterna, körs varje minut och avgränsar på elev-38 (`location` eller värdnamnet i `full_log`).

## Översikt

| Händelse | Loggkälla | Filter | Faktiska värden | Gränsfall |
|---|---|---|---|---|
| 1. Brute force mot SSH | sshd-session, wazuh-alerts-* | elev-38, rule.id 5710/5712/5760/5763, ≥5 på 5 min | 172.20.1.10, oracle25, deploy65, support77 m.fl., 2026-11-15 19:25 UTC | Enstaka fel lösenord på befintligt konto (enstaka 5760) |
| 2. Zonöverträdelse | kernel (nftables), wazuh-archives-* | elev-38, full_log "ZON-IN-DROP" | 172.20.1.2 till 172.20.1.138 port 80, TCP, IN=eth1, 2026-11-16 08:16 UTC | ZON-UT-DROP (min egen utgående trafik som stoppas) |
| 3. Root-kommando | auditd (audisp-syslog), wazuh-archives-* | elev-38, full_log "root-cmd", "type=SYSCALL" och "success=yes" | auid=1000 (student), uid=0, syscall=59, `sudo ls /root`, 2026-11-16 08:11 UTC | SYSCALL med success=no (sökning efter programmet i PATH) |
| 4. Nytt användarkonto | useradd, wazuh-alerts-* | elev-38, rule.id 5902, inte data.shell *nologin* | test38, uid 1001, /bin/bash, 2026-11-16 08:02 UTC | Systemkonto från dnf med /sbin/nologin (filtreras bort på shell) |

---

## Kommentarer

### 1. Brute force mot SSH

Vi letar efter många misslyckade SSH-inloggningar mot elev-38. Raderna skrivs av programmet `sshd-session`. Wazuh har egna regler för detta: 5710/5712 för påhittade användare och 5760/5763 för konton som finns. Händelserna finns i `wazuh-alerts-*`. Monitorn heter **T1110 brute force mot elev-38** (T1110 = Brute Force i MITRE ATT&CK) och slår till först vid minst 5 försök inom 5 minuter.

- **Larmet betyder:** minst 5 misslyckade inloggningsförsök mot elev-38 inom 5 minuter, från en eller flera adresser, vilket tyder på ett brute force-försök.
- **Riktig träff:** ctf-servern 172.20.1.10 provade 12 påhittade användarnamn (oracle25, deploy65, support77 m.fl.) den 15/11 kl. 19:25 UTC (U6.2).
- **Framkallad:** `kontrollera U6.2 start` på jump 2026-11-15 19:24 UTC. Monitorn larmade inom ett par minuter, och kontrollen godkände U6.2.
- **Ska inte larma:** någon som skriver fel lösenord en eller ett par gånger på ett konto som finns (enstaka 5760). Fem eller fler inom 5 minuter larmar – det är ett angrepp, inte en feltryckning.
- **Falskt negativt (teamets fynd 2026-11-12):** en brute force mot det befintliga kontot student på elev-09 gav inget larm, eftersom monitorerna bara räknade 5710/5712. Jag lade till 5760 och 5763 i min monitor den 15/11.
- **Brus, normaltrafik:** 49 träffar på 0,5 h. Normaltrafiken ligger i min egen ström (`/var/log/remote/inmatat/elev-38/normal.log`). Försöken kom i tre klungor (ca 07:10, 07:18 och 07:34–07:36 UTC) med 8–11 försök på 30 sekunder, från minst sex adresser (10.40.1.118, 10.40.2.3, 10.40.2.5, 10.40.3.194, 10.40.3.175 m.fl.) och med påhittade namn som guest, postgres och deploy – monitorn hade larmat ungefär tre gånger, alla falsklarm.
- **Brus, verifierat fönster:** 62 träffar på 261 h (≈ 0,24/h). 61 är förklarade: 49 normaltrafiken och 12 U6.2. En träff den 9/11 är inte utredd (troligen ett eget felskrivet lösenord).
- **Falsklarmsrisk:** tröskeln räknar alla adresser tillsammans. Det fångar distribuerade angrepp men larmar också när flera källor gör några försök var, som i normaltrafiken. En tröskel per data.srcip hade gett färre falsklarm men missat distribuerade angrepp. Med 5760 larmar också någon som skriver fel lösenord fem gånger. Egna tester och ctf-kontroller larmar likadant som ett riktigt angrepp och måste stämmas av mot testloggen.
- **Att tänka på:** 10.40.1.118 ligger i Serverzonen. Enligt flödestabellen får Serverzonen bara nå elev-38 på port 5432 (F10), så i verkligheten hade nftables stoppat de SSH-försöken innan sshd såg dem.

### 2. Zonöverträdelse

Vi letar efter trafik som brandväggen på elev-38 (nftables) stoppar på väg **in**. Det är kärnan som loggar, därför står det `kernel` som program. Ingen standardregel larmar, så raderna finns bara i `wazuh-archives-*`. Vi filtrerar på loggprefixet `ZON-IN-DROP` som jag själv satte sist i kedjan in i `zon.nft`. Wazuh plockar ut fälten `data.action`, `data.srcip`, `data.dstip`, `data.dstport` och `data.protocol`. Monitorn heter **T1046 zonöverträdelse på elev-38** (T1046 = Network Service Discovery) och larmar på första träffen.

- **Larmet betyder:** någon har försökt nå en port på elev-38 som flödestabellen inte tillåter, och brandväggen har stoppat det. Det kan vara kartläggning inför ett angrepp eller en felkonfigurerad tjänst.
- **Riktig träff (framkallad):** från jump `timeout 3 bash -c '</dev/tcp/172.20.1.138/80'` 2026-11-16 08:16 UTC. Inget svar (slutkod 124 = tyst nekande). Två rader ZON-IN-DROP 08:16:36 och 08:16:37 UTC: `SRC=172.20.1.2`, `DST=172.20.1.138`, `DPT=80`, `PROTO=TCP`, `IN=eth1`. Två rader eftersom TCP skickar om SYN när inget svar kommer. Monitorn larmade 08:19 UTC.
- **Ska inte larma:** `ZON-UT-DROP`, alltså min egen utgående trafik som stoppas. Det är en annan händelse (felkonfiguration eller något på servern som försöker ringa ut) och söks inte här.
- **Brus, normaltrafik:** 0 träffar på 0,5 h – inga falsklarm.
- **Brus, verifierat fönster:** 2 träffar på 273 h (≈ 0,007/h), båda mitt eget test. Före testet fanns 0 träffar sedan 5/11.
- **Varför så tyst:** molnbrandväggen stoppar all inkommande trafik från internet på eth0 innan den når servern, och det loggas inte i nftables. Det som kan nå elev-38 är labbnätet (eth1) och teamnätet (eth2). Det är också en blind fläck: försök från internet syns inte i min detektion.
- **Falsklarmsrisk:** egna tester från jump och ctf-kontroller (172.20.1.10) mot slumpade portar larmar likadant som en riktig kartläggning och måste stämmas av mot testloggen. Ett angrepp på en tillåten port (22 eller 5432) syns inte här, eftersom det inte stoppas.

### 3. Kommando som körs som root

Vi letar efter kommandon som en **inloggad person** kör med root-rättigheter, till exempel via sudo. Min auditd-regel från vecka 5 loggar dem med nyckeln `root-cmd` och skickar dem via `audisp-syslog`. Ingen standardregel larmar, så de finns bara i `wazuh-archives-*`, och allt ligger i `full_log`. Monitorn heter **T1548.003 root-kommando på elev-38** (T1548.003 = Sudo and Sudo Caching) och larmar på första träffen.

Ett kommando ger flera auditposter. Nyckeln står bara i `type=SYSCALL`, så vi räknar bara dem. När man skriver `sudo userdel` letar systemet igenom flera mappar i PATH tills programmet hittas, och varje misslyckat försök loggas som `success=no exit=-2`. Därför räknar vi bara `success=yes`. Det gav 9 träffar i stället för 21 för samma kommandon.

- **Larmet betyder:** en inloggad användare har kört ett kommando som root på elev-38 – oftast administration, men kan vara en angripare som tagit över ett konto.
- **Riktig träff (framkallad):** `sudo ls /root` 2026-11-16 08:11 UTC. SYSCALL-poster med `auid=1000` (student), `uid=0`, `syscall=59` (execve), `success=yes`. Monitorn larmade 08:12 UTC.
- **Ska inte larma:** `success=no`-poster från sökningen i PATH. De filtreras bort på `success=yes`.
- **Brus, normaltrafik:** 0 träffar på 0,5 h – inga falsklarm.
- **Brus, verifierat fönster:** 149 träffar på 273 h (≈ 0,55/h). Nästan allt är min egen administration: cirka 125 den 8–9/11 (rsyslog, restorecon, auditd och omstarter i vecka 5), cirka 8 den 12/11 och 13 den 16/11 (testerna här). Högst falsklarmsrisk av de fyra.
- **Falsklarmsrisk:** allt administrativt arbete med sudo larmar likadant som en angripare med ett stulet konto. Ett sudo-kommando ger dessutom flera träffar, eftersom sudo och kommandot och dess hjälpprogram körs som root. Att undanta vanliga kommandon minskar bruset men skapar en blind fläck.

### 4. Nytt användarkonto

Vi letar efter att någon skapar ett konto – en angripare gör det för att kunna komma tillbaka senare (persistence). Raderna skrivs av `useradd`. Wazuh har en egen regel (5902 "New user added to the system"), så händelsen finns i `wazuh-alerts-*`. Monitorn heter **T1136 nytt konto på elev-38** (T1136 = Create Account) och larmar på första träffen.

- **Larmet betyder:** någon har skapat ett konto med inloggningsbar shell på elev-38 – kan vara en bakdörr för att komma tillbaka.
- **Riktig träff (framkallad):** `sudo useradd -m test38` 2026-11-16 08:02:48 UTC. `data.dstuser: test38`, `data.uid: 1001`, `data.shell: /bin/bash`, `data.home: /home/test38`, rule.level 8. Monitorn larmade 08:03 UTC. Kontot togs bort efteråt med `sudo userdel -r test38`.
- **Ska inte larma:** systemkonton som skapas när ett paket installeras med dnf (`/sbin/nologin`). De filtreras bort på shell, inte på uid, så att ett konto som en angripare skapar med `-r` ändå syns (se elev-46).
- **Brus, normaltrafik:** 0 träffar på 0,5 h – inga falsklarm.
- **Brus, verifierat fönster:** 1 träff på 273 h (≈ 0,004/h), mitt eget test.
- **Falsklarmsrisk:** legitim kontoadministration larmar likadant. Samma `sudo useradd` ger också träffar i händelse 3 (root-kommando).

---

## Testlogg

| Tid (UTC) | Vem | Från | Mot | Vad (kommando) | Förväntat larm |
|---|---|---|---|---|---|
| 2026-11-15 19:24 | Naima | ctf (172.20.1.10) | elev-38 | `kontrollera U6.2 start` på jump, 12 försök med påhittade användare | Brute force (5710/5712) |
| 2026-11-16 08:02 | Naima | elev-38 | elev-38 | `sudo useradd -m test38`, sedan `sudo userdel -r test38` | Nytt konto (5902), root-kommando |
| 2026-11-16 08:11 | Naima | elev-38 | elev-38 | `sudo ls /root` | Root-kommando |
| 2026-11-16 08:16 | Naima | jump | elev-38 | `timeout 3 bash -c '</dev/tcp/172.20.1.138/80'` | Zonöverträdelse (ZON-IN-DROP) |

## Triagelogg

### Larm: T1110 brute force mot elev-38

Triagerad av Naima den 16/11 enligt teamets playbook [brute-force.md](../playbooks/brute-force.md).

- **Observation:** 12 misslyckade SSH-inloggningar mot elev-38, alla 2026-11-15 19:25 UTC, rule.id 5710 ("Attempt to login using a non-existent user"), data.srcip 172.20.1.10, data.srcuser påhittade namn (oracle25, deploy65, support77 m.fl.). Monitorn larmade kort därefter.
- **Slog källan mot fler servrar?** Sökning `data.srcip: 172.20.1.10` utan värdfilter, 19:20–19:35 UTC: 12 träffar, alla mot elev-38. Inga försök mot teamets andra servrar.
- **Följdes det av en lyckad inloggning?** Sökning `rule.id: 40112 or rule.id: 5715`, 19:20–19:45 UTC: 0 träffar. Ingen kom in.
- **Vad hände:** någon försökte gissa sig in på elev-38 med påhittade användarnamn. Alla försök misslyckades.
- **Vad berördes:** bara elev-38. Inga konton påverkades, eftersom användarnamnen inte finns.
- **Vad ska göras:** avfärda. Källan är ctf-servern (172.20.1.10), en känd intern källa. Alla försök misslyckades, och tiden stämmer med testloggen (19:24 UTC, Naima, `kontrollera U6.2 start`).
- **Att tänka på:** om ctf-servern loggar in som root med nyckel strax efter försöken kopplar Wazuh ihop det till regel 40112 ("failures followed by a success"). Det är ctf-kontrollen och inget lyckat angrepp: observationerna är `Accepted publickey`, kontot root och källan 172.20.1.10. Det hände inte den här gången.

### Larm: T1136 nytt konto på elev-38

- **Observation:** rule.id 5902, elev-38, 2026-11-16 08:02:48 UTC. test38, uid 1001, /bin/bash, home /home/test38. Samma minut SYSCALL-poster med `root-cmd` från auid=1000 (student).
- **Vad hände:** student skapade ett inloggningsbart konto med sudo.
- **Vad berördes:** elev-38, kontot test38.
- **Vad ska göras:** avfärda – stämmer med testloggen (08:02 UTC, Naima, `sudo useradd -m test38`). Kontot är borttaget.

### Larm: T1548.003 root-kommando på elev-38

- **Observation:** SYSCALL-poster med `key="root-cmd"`, `success=yes`, `auid=1000`, `uid=0`, elev-38, 2026-11-16 08:11:52 UTC.
- **Vad hände:** student körde ett kommando som root via sudo.
- **Vad berördes:** elev-38. Kommandot listade innehållet i /root och ändrade ingenting.
- **Vad ska göras:** avfärda – stämmer med testloggen (08:11 UTC, Naima, `sudo ls /root`).

### Larm: T1046 zonöverträdelse på elev-38

- **Observation:** två rader ZON-IN-DROP 2026-11-16 08:16:36–37 UTC, `SRC=172.20.1.2` (jump), `DST=172.20.1.138`, `DPT=80`, TCP, `IN=eth1`.
- **Vad hände:** jump försökte nå port 80 på elev-38. Brandväggen stoppade det tyst.
- **Vad berördes:** elev-38, port 80. Ingen kom in, eftersom paketen kastades.
- **Vad ska göras:** avfärda – känd intern källa, ett fåtal paket mot en enda port, och det stämmer med testloggen (08:16 UTC, Naima). Hade det varit många portar från samma källa hade det varit en portskanning och skulle utredas.
