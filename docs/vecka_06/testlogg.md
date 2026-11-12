# Testlogg – team Alladinarna

Varje framkallning, test och kontroll som kan ge larm skrivs in **innan** den körs. Alla tider i UTC.
Rader märkta *(i efterhand)* skrevs in efter att testet körts, med tider från terminal- och Wazuh-loggar.

| Tid (UTC) | Vem | Från | Mot | Vad (kommando) | Förväntat larm |
|---|---|---|---|---|---|
| 2026-11-11 08:38 | Hugo | elev-46 | elev-46 | `sudo useradd test46` *(i efterhand)* | Nytt konto (5902), root-kommando |
| 2026-11-11 09:01 | Hugo | elev-46 | elev-46 | `sudo useradd -r test46r` *(i efterhand)* | Nytt konto (5902), root-kommando |
| 2026-11-11 11:44 | Hugo | jump | elev-46 | `/dev/tcp/172.20.1.146/80` *(i efterhand)* | Zonöverträdelse |
| 2026-11-12 ~08:12 | Hugo | jump | elev-09 | `ssh fejk1–6@172.20.1.109`, 18 försök *(i efterhand)* | Brute force |
| 2026-11-12 ~08:33 | Hugo | jump | elev-09 | `ssh fejk1–6@…` 18 försök + `ssh student@…` 24 försök *(i efterhand)* | Brute force; student gav 5760/5763 men inget larm (falskt negativt) |
| 2026-11-12 ~09:01 | Hugo | jump | elev-09 | `/dev/tcp/172.20.1.109/80` *(i efterhand)* | Zonöverträdelse |
| 2026-11-12 09:21 | Hugo | elev-46 | elev-46 | `sudo useradd test1`, `userdel -r test1` 09:34 *(i efterhand)* | Nytt konto (5902), root-kommando |
| 2026-11-12 12:16 | Hugo | elev-46 / jump | elev-46 | `sudo useradd -m lastest46`, ssh-nyckel, `usermod -L -e 1`, inloggningsförsök, `userdel -r` | Nytt konto (5902), root-kommando |
| 2026-11-12 14:15 | Hugo | elev-46 | elev-46 | `sudo useradd -m lastest46` | Nytt konto (5902), root commando |
