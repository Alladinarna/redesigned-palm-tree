# Vecka 5 – Central logginsamling igång (milstolpe 5)

> Teamets servrar skickar system-, autentiserings- och brandväggsloggar till den gemensamma loggservern över skyddad transport, insamlingen är verifierad med en spårbar testhändelse, och skyddet av loggkedjan är dokumenterat med åtkomst, lagringstid och beteende vid onåbar mottagare. (Boiler Room: Zonuppdraget)

Milstolpen stäms av på checkpointen **måndag 9/11**. Den ska ligga i `main` senast söndag 8/11.

| Fil | Innehåll | Status |
|---|---|---|
| [loggkallekarta.md](loggkallekarta.md) | Loggkällor per server med klistrade exempelrader | elev-24 ifylld och verifierad 2/11, övriga tomma |
| [urval.md](urval.md) | Fem frågor, urval och strukna källor | Utkast att granska i workshop 1 |
| [loggstrategi.md](loggstrategi.md) | Loggstrategi version 1 | Utkast |
| [skyddsbeskrivning.md](skyddsbeskrivning.md) | Skyddet av loggkedjan (fyra rubriker och ett scenario) | elev-24 ifylld med belägg och kötest 2/11. Central lagringstid och fylld kö är inte kontrollerade |
| [verifiering.md](verifiering.md) | Testhändelser och var de hittades centralt | elev-24 klar 2/11 (alla källor över TLS), övriga fylls i i workshop 2 |
| [logginsamling/](logginsamling/) | `90-logg.conf`, `50-root-cmd.rules`, `ca.pem`, `ladda-logg.sh` | Körda på elev-24 2/11 08:07Z (RC=0) |

Regelverket uppdaterades i samma veva: D5 släpper tcp/6514 i stället för 514 i alla fyra `*-zon.nft`, testfallen är ändrade och F25 (Klientzon → Loggzon) är ny i [flödestabellen](../vecka_03/flodestabell.md).

## Ordning på varje server (workshop 2)

Ordningen följer studieguiden: tid först, flöde sedan, vidarebefordran därefter, testhändelse sist.

```
# från repot på din dator
scp -r docs/vecka_04/zonuppdelning docs/vecka_05/logginsamling lab:

# på servern, två SSH-sessioner öppna
chronyc tracking ; timedatectl                 # 1. tid
cd ~/zonuppdelning && sudo bash ladda-zon.sh   # 2. flöde: D5 på tcp/6514 (nödbroms 5 min)
#    ny session via jump fungerar? -> sudo systemctl stop nodbroms.timer
cd $(hostname -s) && bash test.sh testfall.csv #    D5-till ska bli oppen, D5-nek-klartext tyst
cd ~/logginsamling && sudo bash ladda-logg.sh  # 3. TLS-vidarebefordran och auditd, 4. testhändelse
```

På jump:
- `loggsök <id>`: kontrollera att kanalen är TLS och att värdnamn och tid stämmer. Fyll i [verifiering.md](verifiering.md).
- `kontrollera U5.1`, `U5.2` och `U5.3` (U5.3 före 9/11). Lämna själv in flaggorna med `lämna-flagga`.

CA-certifikatet ligger i repot. Studieguiden hämtar det med `curl http://log.sec.chas-lab.dev/ca.pem`, men vårt regelverk nekar tcp/80 mot log (testfallet `D7-nek`). `ladda-logg.sh` kontrollerar fingeravtrycket innan certet installeras.

## Fördelning (förslag, flytta på brädan)

| Vem | Server | Uppgift |
|---|---|---|
| Stef | elev-24 | Loggkedjan (`logginsamling/`) och att regelverket laddas om |
| Hugo | elev-46 | Urval och loggstrategi (workshop 1) |
| Gabriel | elev-09 | auditd och U5.3, raden F25 |
| Naima | elev-38 | Skyddsbeskrivning och verifiering |

Alla fyller i loggkällekartan och verifieringen för sin egen server.

## Klart när

- [ ] `loggsök` visar en testhändelse över TLS med rätt värdnamn och tid från alla fyra servrar
- [ ] sshd/sudo, paketfiltret och auditd (rätt auid) kommer fram centralt
- [ ] U5.2 är visad: kön håller vid avbrott och omstart
- [ ] `test.sh` är omkörd och testprotokollen och spårbarhetslistorna är uppdaterade (D5 verifierad)
- [ ] Loggkällekarta, urval, skyddsbeskrivning, verifiering och loggstrategi är granskade och mergade
