# Verifieringsanteckning – vecka 5

Workshop 2. Sök centralt på jump med `loggsök SÖKORD`. Raden börjar med mottagningstiden på log (UTC) och kanalen (TLS eller KLARTEXT). Efter lodstrecket kommer avsändarens tidsstämpel, adress, värdnamn, tagg och text.

**Avvikelse** betyder fel kanal, fel värdnamn, för stor skillnad mellan avsändartid och mottagningstid, eller att raden inte hittas.

## elev-24 (2026-11-02)

Konfigurationen installerades 08:07:40Z med [ladda-logg.sh](logginsamling/ladda-logg.sh). TLS-kontrollen gav `subject=CN=log.sec.chas-lab.dev`, `issuer=CN=ITSX26 labb-CA` och `Verify return code: 0 (ok)`.

| Identifierare | Avsändartid (UTC) | Mottaget på log (UTC) | Värdnamn | Källa | Söksträng | Kanal | Avvikelse? |
|---|---|---|---|---|---|---|---|
| sparbarhet-elev-24-20261102T080742Z | 08:07:42.094541 | 08:07:42.377 | elev-24 | logger (user.notice) | id:t | TLS | Nej |
| (auditpost för logger-kommandot ovan, körd med sudo) | 08:07:42.089538 | 08:07:42.376 | elev-24 | auditd via audisp-syslog (EXECVE) | id:t | TLS | Nej |
| msg=audit(1793606865.111:1230) | 08:07:45.113603 | 08:07:45.360 | elev-24 | auditd (SYSCALL, `key="root-cmd"`, `auid=1000`, `AUID="student"`) | `root-cmd` | TLS | Nej |
| sudo[22225] | 08:09:45.324280 | 08:09:45.613 | elev-24 | sudo (authpriv): `1 incorrect password attempt` | `sudo` | TLS | Nej |
| kotest-elev-24-20261102T081046Z | 08:10:47.212852 | 08:12:06.490 | elev-24 | logger, skickad medan tcp/6514 var blockerad | id:t | TLS | Nej. Fördröjningen är avsiktlig (kötestet, se [skyddsbeskrivning.md](skyddsbeskrivning.md) avsnitt 4) |
| sshd-session[22415] | 08:12:32.389307 | 08:12:32.825 | elev-24 | sshd (authpriv): `Accepted publickey for student from 172.20.1.2 port 38950` | `Accepted publickey` | TLS | Nej |
| ZON-UT-DROP (nekad tcp/22 till 10.40.1.146) | 08:13:00.023266 | 08:13:00.261 | elev-24 | paketfiltret (kern) | `ZON-UT-DROP` | TLS | Nej |

Avsändartiden har mikrosekunder och tidszonen `+00:00` (RFC 5424-mallen). chrony låg 0,00007 s efter NTP (`chronyc tracking`, Leap status Normal).

| omstart-elev-24-20261102T082826Z | 08:28:26.111873 | 08:30:22.073 | elev-24 | logger efter omstarten | id:t | TLS | Ja: cirka 2 minuters fördröjning. Kön skickades först 08:30:21Z, se [skyddsbeskrivning.md](skyddsbeskrivning.md) avsnitt 4 |
| sshd-session[2321] | 08:29:17.705947 | 08:30:22.074 | elev-24 | sshd efter omstarten | `Accepted publickey` | TLS | Samma fördröjning |

| omstart2-elev-24-20261102T083925Z | 08:39:25.127370 | 08:41:14.147 | elev-24 | logger efter omstarten 08:38Z (D5 låst till eth1) | id:t | TLS | Ja: cirka 1 min 49 s fördröjning, samma orsak som ovan |
| fore-omstart2-20261102T083819Z | 08:38:19.403428 | 08:38:19.515 | elev-24 | logger före omstarten, efter att `oifname "eth1"` laddats | id:t | TLS | Nej |

**Före bytet:** den sista raden från elev-24 i klartext togs emot 08:07:21.609Z (`KLARTEXT`). Strax innan, 08:07:15Z och 08:07:16Z, kom två `ZON-UT-DROP`-rader för SYN till `DST=172.20.1.58 DPT=514`. Det visar att det nya regelverket stoppade nya anslutningar till tcp/514. Efter rsyslog-bytet 08:07:40Z finns inga klartextrader från elev-24 (`loggsök elev-24 | grep KLARTEXT\| grep KLARTEXT`, kontrollerat 08:15Z).

## elev-09, elev-38 och elev-46

| Identifierare | Avsändartid (UTC) | Mottaget på log (UTC) | Värdnamn | Källa | Söksträng | Kanal | Avvikelse? |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Felsökning nedifrån och upp (studieguiden)

1. Skrivs händelsen i den lokala loggen? (`sudo tail /var/log/messages`)
2. Säger rsyslogs egen logg något om mottagaren? (`journalctl -u rsyslog`)
3. Lämnar paketen servern? (`sudo tcpdump -nn -i eth1 host 172.20.1.58 and port 6514` medan du skickar)
4. Kommer trafiken fram? Syns svar från log, eller bara upprepade SYN?
