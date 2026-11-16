## Larm: brute force mot elev-09 (rule.id 5712)
- Observation: det kom 32 misslyckade SSH-händelser från 172.20.1.2 mot elev-09 på ungefär en minut (runt 09:14), och alla var på påhittade användare (fejk3 till fejk6). Det är regel 5710, 5503 och 5712 som gått igång. Inget försök lyckades.
- Vad hände: någon försökte brute forca sig in på elev-09. 5712 är den som kopplar ihop alla de misslyckade försöken till ett larm. Det gick inte, inget konto kom in.
- Vad berördes: bara elev-09. Alla träffar från 172.20.1.2 ligger på elev-09/syslog.log, så källan rörde ingen annan server.
- Vad ska göras: källan är 172.20.1.2, alltså jump, som är intern. Så jag skulle kolla vem som satt på jump just då. Allt misslyckades så det brinner inte, men en intern maskin som brute forcar är ändå nåt man vill utreda.

## Larm: kommando som root (rule.id 5402)
- Observation: student körde sudo systemctl restart chronyd på elev-09 kl 09:46 och det kördes som root (data.dstuser root). Regel 5402, från en interaktiv session (TTY pts/0, PWD /home/student).
- Vad hände: en inloggad användare körde ett kommando som root via sudo. 5402 larmar på lyckad sudo till root.
- Vad berördes: bara elev-09. Kommandot var en omstart av chronyd, alltså tidssynk-tjänsten.
- Vad ska göras: det här är ju en helt vanlig admin-grej, så jag avfärdar den. Skäl som någon annan kan kolla: det kom från en interaktiv session (pts/0, inte ett skript), kontot är student som är den vanliga på elev-09, och kommandot var ofarligt (bara en omstart av tidstjänsten). Hade det varit ett okänt konto eller ett farligt kommando, typ skapa användare eller peta i sudoers, hade jag eskalerat istället.

## Larm: zonöverträdelse (ZON-IN-DROP)
- Observation: ett par blockerade TCP-SYN-paket från 172.20.1.2 (jump) mot elev-09 på port 80, kl 10:01. data.action ZON-IN-DROP, PROTO=TCP, DPT=80. Ligger i wazuh-archives, inte alerts (låg nivå, blir ingen alert).
- Vad hände: brandväggen på elev-09 droppade en anslutning som flödestabellen inte tillåter. Jump får inte prata port 80 med elev-09, så den stoppades redan i paketfiltret.
- Vad berördes: bara elev-09, port 80. Källan är jump (172.20.1.2). Ingen kom in, paketet droppades.
- Vad ska göras: en enstaka blockad anslutning är oftast ett misstag eller nån som testar, och den är ju redan stoppad. Jag avfärdar: känd intern källa (jump), ett fåtal paket, redan droppat av brandväggen. Men hade det kommit många drops mot olika portar från samma källa hade det varit en portscan, och då hade jag utrett källan.

## Larm: nytt användarkonto (rule 5902)
- Observation: rule.id 5902, nivå 8, T1136. elev-46, 2026-11-12 09:21:57 UTC. useradd: name=test1, UID=1001, GID=1001, home=/home/test1, shell=/bin/bash, from=/dev/pts/1. Samma sekund: rule.id 5402, data.srcuser student, data.command /sbin/useradd test1, tty pts/0.
- Vad hände: inloggade användaren student skapade ett vanligt inloggningsbart konto med sudo. Skillnaden pts/0–pts/1 beror troligen på att sudo kör kommandot i en egen terminal (use_pty).
- Vad berördes: elev-46, kontot test1. Utan värdfilter finns test1 bara på elev-46 – inget tecken på att samma konto skapats på fler servrar.
- Vad ska göras: avfärda – kontot skapades av student som en planerad framkallning i triageövningen, och sudo-posten visar vem och vilket kommando. Kontot är borttaget. 
## Larm: brute force som lyckades (rule.id 40112) – övningsexempel
- Observation: flera misslyckade lösenordsförsök mot kontot student på elev-09 från 172.20.1.2, följt av en lyckad inloggning som student. Regel 40112, nivå 12 (mycket högre än 5712). Fyra larm mellan 09:33 och 09:45.
- Vad hände: en brute force mot student som till slut lyckades. Det är här skillnaden mot 5712 blir viktig – i 5712 kom ingen in, här kom någon faktiskt in på kontot.
- Vad berördes: elev-09, kontot student. Källan är 172.20.1.2 (jump), samma som i försöket innan.
- Vad ska göras: eskalera direkt, det här ser ut som en möjlig kontoövertagande. Jag skulle spärra eller tvinga lösenordsbyte på student, kolla vad som hände på elev-09 efter inloggningen (vilka kommandon som kördes), och utreda källan 172.20.1.2. Nivå 12 betyder att en analytiker ska titta på den, inte avfärda.

## Larm: nytt användarkonto (rule 5902) – verifiering av playbook
- Triagerad av: Hugo (elev-46)
- Observation: rule.id 5902, elev-46, 2026-11-12 12:16:52 UTC. name=lastest46, uid 1001, /bin/bash, home /home/lastest46, from=/dev/pts/1. Larm 12:17 UTC, avslutat 12:22. 5402 samma sekund: student, /sbin/useradd -m lastest46 (även /bin/passwd lastest46). 5715 12:22:20: lastest46 inloggad med nyckel från 172.20.1.2.
- Vad hände: student skapade ett testkonto med sudo och loggade in på det från jump.
- Vad berördes: elev-46, kontot lastest46. Utan värdfilter finns lastest46 bara på elev-46.
- Vad ska göras: avfärda – stämmer med testloggen (12:16, Hugo, useradd, nyckelinloggning). Kontot låstes med usermod -L -e 1; inloggning med nyckel nekades ("account has expired"). Upplåsning fungerade. Kontot borttaget, nyckeln på jump raderad.
- Fynd i playbooken: from= var svårt att hitta (steg 4 förtydligat), flera 5402-poster (steg 5 förtydligat), saknat steg för om nya kontot använts (nytt steg 7).

## Falskt negativt: brute force mot befintligt konto (rule 5760/5763)
- Triagerad av: Hugo (elev-46)
- Observation: 23 × rule.id 5760 "authentication failed" och 1 × 5763 (08:43:21 UTC, med previous_output) på elev-09, data.dstuser student, data.srcip 172.20.1.2. Brute force-monitorn larmade inte.
- Vad hände: upprepade felaktiga lösenord mot ett konto som finns. Wazuh känner igen det som brute force (5763: 8 försök på 120 s från samma källa), men teamets monitor räknar bara 5710/5712, som gäller påhittade användare.
- Vad berördes: elev-09, kontot student. Ingen lyckad inloggning (5715) från 172.20.1.2 under försöken 08:33–08:43; de tre lyckade inloggningarna från samma källa (08:01, 08:27, 08:28) ligger före och är Gabriels egna via jump.
- Vad ska göras: själva händelsen avfärdas – den stämmer med testloggen (~08:33, Hugo, ssh student@…). Men detektionen har ett falskt negativt: en angripare som gissar på ett riktigt användarnamn syns inte. Monitorn utökas med 5760/5763, och brute-force.md uppdateras. Gränsfallet "fel lösenord på befintligt konto" gäller bara enstaka försök.

  ## Larm: brute force mot elev-09 – korstest av brute-force.md
- Triagerad av: Hugo (elev-46), följde Gabriels playbook. Gabriel antecknade.
- Observation: 15 misslyckade inloggningar, rule.id 5710, elev-09, 2026-11-12 13:42 UTC. data.srcip 172.20.1.2, data.srcuser fejk7.
- Vad hände: upprepade inloggningsförsök med ett påhittat användarnamn från jump.
- Vad berördes: bara elev-09 – sökning på data.srcip 172.20.1.2 utan värdfilter gav inga försök mot andra servrar. Ingen lyckad inloggning från källan i fönstret.
- Vad ska göras: avfärda – stämmer med testloggen (13:42, Gabriel, ssh fejk7@…).
- Fynd i playbooken: oklart var man börjar (startrad tillagd); tidsfönstret hölls inte runt larmet, en sökning gav 179 träffar över 24 h (förtydligat); inget om vad man gör när testloggen inte matchar (tillagt: behandla som skarpt); testloggens plats saknades (tillagd). Detektionen missar brute force mot riktiga konton (5760/5763), samma lucka som i posten "Falskt negativt".
