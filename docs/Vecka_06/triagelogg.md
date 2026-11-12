## Larm: brute force mot elev-09 (rule.id 5712)
- Observation: det kom 32 misslyckade SSH-händelser från 172.20.1.2 mot elev-09 på ungefär en minut (runt 09:14), och alla var på påhittade användare (fejk3 till fejk6). Det är regel 5710, 5503 och 5712 som gått igång. Inget försök lyckades.
- Vad hände: någon försökte brute forca sig in på elev-09. 5712 är den som kopplar ihop alla de misslyckade försöken till ett larm. Det gick inte, inget konto kom in.
- Vad berördes: bara elev-09. Alla träffar från 172.20.1.2 ligger på elev-09/syslog.log, så källan rörde ingen annan server.
- Vad ska göras: källan är 172.20.1.2, alltså jump, som är intern. Så jag skulle kolla vem som satt på jump just då. Allt misslyckades så det brinner inte, men en intern maskin som brute forcar är ändå nåt man vill utreda.

## Larm: brute force som lyckades (rule.id 40112)
- Observation: flera misslyckade lösenordsförsök mot kontot student på elev-09 från 172.20.1.2, följt av en lyckad inloggning som student. Regel 40112, nivå 12 (mycket högre än 5712). Fyra larm mellan 09:33 och 09:45.
- Vad hände: en brute force mot student som till slut lyckades. Det är här skillnaden mot 5712 blir viktig – i 5712 kom ingen in, här kom någon faktiskt in på kontot.
- Vad berördes: elev-09, kontot student. Källan är 172.20.1.2 (jump), samma som i försöket innan.
- Vad ska göras: eskalera direkt, det här ser ut som en möjlig kontoövertagande. Jag skulle spärra eller tvinga lösenordsbyte på student, kolla vad som hände på elev-09 efter inloggningen (vilka kommandon som kördes), och utreda källan 172.20.1.2. Nivå 12 betyder att en analytiker ska titta på den, inte avfärda.

## Larm: kommando som root (rule.id 5402)
- Observation: student körde `sudo systemctl restart chronyd` på elev-09 kl 09:46 och det kördes som root (data.dstuser root). Regel 5402, från en interaktiv session (TTY pts/0, PWD /home/student).
- Vad hände: en inloggad användare körde ett kommando som root via sudo. 5402 larmar på lyckad sudo till root.
- Vad berördes: bara elev-09. Kommandot var en omstart av chronyd, alltså tidssynk-tjänsten.
- Vad ska göras: det här är ju en helt vanlig admin-grej, så jag avfärdar den. Skäl som någon annan kan kolla: det kom från en interaktiv session (pts/0, inte ett skript), kontot är student som är den vanliga på elev-09, och kommandot var ofarligt (bara en omstart av tidstjänsten). Hade det varit ett okänt konto eller ett farligt kommando, typ skapa användare eller peta i sudoers, hade jag eskalerat istället.