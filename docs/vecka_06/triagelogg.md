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

## Larm: nytt användarkonto (rule.id 5902)
- Observation: ett nytt konto test12 skapades på elev-09 kl 10:19. uid 1001, gid 1001, home /home/test12, shell /bin/bash. Regel 5902, nivå 8, från en interaktiv session (pts/1).
- Vad hände: en ny användare lades till på systemet. 5902 larmar på det. uid 1001 betyder att det är ett vanligt interaktivt konto (≥1000), inte ett system-/tjänstekonto.
- Vad berördes: bara elev-09, själva det nya kontot test12.
- Vad ska göras: nya interaktiva konton är en klassisk persistence-grej – en angripare skapar ett konto för att kunna komma tillbaka, så default är misstänkt. Jag kollar vem som skapade det och om det var planerat. Här var det student som la till det som ett test, så jag avfärdar med skäl: känd admin, interaktiv session, känd anledning. Men var kontot skapat av ett okänt konto eller utan förklaring hade jag eskalerat – det kan vara en bakdörr.

## Larm: brute force som lyckades (rule.id 40112) – övningsexempel
- Observation: flera misslyckade lösenordsförsök mot kontot student på elev-09 från 172.20.1.2, följt av en lyckad inloggning som student. Regel 40112, nivå 12 (mycket högre än 5712). Fyra larm mellan 09:33 och 09:45.
- Vad hände: en brute force mot student som till slut lyckades. Det är här skillnaden mot 5712 blir viktig – i 5712 kom ingen in, här kom någon faktiskt in på kontot.
- Vad berördes: elev-09, kontot student. Källan är 172.20.1.2 (jump), samma som i försöket innan.
- Vad ska göras: eskalera direkt, det här ser ut som en möjlig kontoövertagande. Jag skulle spärra eller tvinga lösenordsbyte på student, kolla vad som hände på elev-09 efter inloggningen (vilka kommandon som kördes), och utreda källan 172.20.1.2. Nivå 12 betyder att en analytiker ska titta på den, inte avfärda.
