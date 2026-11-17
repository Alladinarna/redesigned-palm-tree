# Härdningslista – elev-46

| Nr | Åtgärd | Motivering – varför just här | Förväntad effekt | Hur den verifieras | Skript? |
|---|---|---|---|---|---|
| 1 | Stäng av lösenordsinloggning i SSH | sshd -T visade passwordauthentication yes, lösenordet kan angripare nu gissa sig till och logga in | Angripare ska inte kunna gissa sig till lösenordet (bruteforce) | sshd -T ska visa passwordauthentication no | ja |
| 2 | Förbjud root- inloggning i SSH | sshd -T visade permitrootlogin without-password, med root kommer man åt allt på servern medans student är mer begränsad. | En nagripare ska inte kunna logga in direkt på root utan först ett användarkonto- ett extra hinder | sshd -T ska visa permitrootlogin no | ja |
| 3 | Dölj versionen i httpds server: -header | curl -I visade server: Apache/2.4.62 (rocky Linux), med exakt version av systemet kan angripare kolla upp kända sårbarheter | Angripare får inte reda på version | curl -I ska visa server: apache utan version | Ja |
| 4 | Uppdatera systemet | Uppdateringar täpper till kända säkerhets hå som tillverkaren hittat | Kända sårbarheter tilltäppta | dnf check-update ska ge felkod 0 | nej – nya uppdateringar släpps löpande, så skriptet kan säga GÄLLER INTE trots att inget har ändrats på servern. Kontrolleras därför manuellt. |
