# Verifieringsanteckning – vecka 5

Workshop 2. En testhändelse per källa och server. `ladda-logg.sh` skickar en `sparbarhet-<server>-<tid>`-händelse. CTF-identifierarna kommer från `kontrollera U5.x` på jump.

Sök centralt på jump med `loggsök SÖKORD`. Raden börjar med mottagningstiden på log (UTC) och kanalen (TLS eller KLARTEXT). Efter lodstrecket kommer avsändarens tidsstämpel, adress, värdnamn, tagg och text.

**Avvikelse** betyder fel kanal (KLARTEXT), fel värdnamn, mer än fem minuter mellan avsändartid och mottagningstid, eller att raden inte hittas.

| Identifierare | Ungefärlig tid (UTC) | Värdnamn | Källa | Söksträng | Hittad centralt? | Avvikelse? |
|---|---|---|---|---|---|---|
| | | elev-24 | logger (user.notice) | | | |
| | | elev-24 | sshd (authpriv), inloggning via jump | `Accepted publickey for student from 172.20.1.2` | | |
| | | elev-24 | paketfiltret (kern), t.ex. `timeout 2 bash -c 'exec 3<>/dev/tcp/10.40.1.146/22'` | `ZON-UT-DROP` | | |
| | | elev-24 | auditd, `sudo /usr/bin/touch /tmp/ID` (U5.3) | ID:t | | |
| | | elev-09 | logger (user.notice) | | | |
| | | elev-38 | logger (user.notice) | | | |
| | | elev-46 | logger (user.notice) | | | |

## Felsökning nedifrån och upp (studieguiden)

1. Skrivs händelsen i den lokala loggen? (`sudo tail /var/log/messages`)
2. Säger rsyslogs egen logg något om mottagaren? (`journalctl -u rsyslog`)
3. Lämnar paketen servern? (`sudo tcpdump -nn -i eth1 host 172.20.1.58 and port 6514` medan du skickar)
4. Kommer trafiken fram? Syns svar från log, eller bara upprepade SYN? Upprepade SYN betyder att regelverket (D5) inte släpper tcp/6514.
