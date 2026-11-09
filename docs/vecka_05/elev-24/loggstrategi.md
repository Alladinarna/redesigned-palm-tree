# Loggstrategi – elev-24, version 1 (vecka 5)

Loggkällekartan och urvalet från workshop 1 utgör loggstrategins första version. Den byggs på i vecka 6 (detektioner), vecka 7 (härdning som följs upp i logg) och vecka 9 (beslutsunderlag).

## Varför loggarna samlas centralt

Uppdragsgivaren måste i efterhand kunna visa vem som gjort vad. En logg som bara finns lokalt kan raderas av den som tagit sig in på servern, försvinner om servern går förlorad och kan inte läggas ihop med andra servrars loggar. Därför lämnar loggarna servern så fort händelsen inträffat.

Kraven kommer från MCFFS 2026:11:
- 4 kap. 21 §: säkerhetsloggning
- 4 kap. 22 §: analys av säkerhetsloggar
- 4 kap. 23 §: robust och korrekt tid
- 4 kap. 25 §: kryptering vid överföring

## Vad som samlas in

Urvalet styrs av fem frågor ([fem-fragor-och-urval.md](fem-fragor-och-urval.md)). Källorna är beskrivna i [loggkällekartan](loggkallekarta.md).

| Källa | Fråga |
|---|---|
| Autentisering (sshd, sudo) | U1, U2 |
| auditd: root-kommandon med auid | U2 |
| Paketfiltret (`ZON-IN-DROP` / `ZON-UT-DROP`) | U3 |
| Systemloggen (rsyslog, chronyd, systemd) | U4, U5 |

Strukna källor och skälen till det står i urvalet.

## Hur loggarna skickas

| Del | Val | Belägg |
|---|---|---|
| Flöde | D5 i flödestabellen: varje server → log 172.20.1.58, TCP 6514. Designrader F11–F14 och F25 (Klientzonen) | [flodestabell.md](../../vecka_03/flodestabell.md), testfall `D5-till` och `D5-nek-klartext` i varje servers testfall.csv |
| Transport | TLS (gtls). Servern kontrollerar loggserverns certifikat mot kursens CA, och namnet ska vara `log.sec.chas-lab.dev` (`x509/name`). Klartext på tcp/514 nekas | [90-logg.conf](90-logg.conf), kursens CA i `/etc/pki/rsyslog/ca.pem` (SHA-256 `2A:B7:EE:…:0C:53`) |
| Format | RFC 5424 (`RSYSLOG_SyslogProtocol23Format`) med delsekunder och tidszon | 90-logg.conf |
| Tid | chrony mot ntp.hetzner.com (D4/F19), tidszon UTC | `chronyc tracking`, `timedatectl` |
| Avbrott | Diskstödd kö som sparas vid avstängning och har obegränsat antal omförsök, högst 256 MB | 90-logg.conf, U5.2 |
| Root-kommandon | auditd-regeln `root-cmd` och syslog-pluginet | `/etc/audit/rules.d/50-root-cmd.rules`, U5.3 |

## Hur loggarna skyddas

Se [skyddsbeskrivning.md](skyddsbeskrivning.md): vem som kan ändra eller radera loggen lokalt och centralt, lagringstid, beteende när mottagaren inte går att nå, och ett scenario med en angripare som har root.

## Koppling till tillgångarnas klassning

Alla fyra servrar skickar samma urval. Det gör att en händelse kan följas mellan zonerna, till exempel från DMZ via Serverzonen till Databaszonen (F9 och F10).

## Öppna punkter

- Central lagringstid är okänd. Fråga utbildaren.
- Journalen sparas bara i minnet (`Storage=auto` utan `/var/log/journal`). Ta ställning till om den ska ligga på disk.
- httpd-loggarna är uppskjutna till vecka 6 och 8.
