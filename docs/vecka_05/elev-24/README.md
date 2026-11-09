# Vecka 5 – Central logginsamling igång (milstolpe 5) – elev-24

> Teamets servrar skickar system-, autentiserings- och brandväggsloggar till den gemensamma loggservern över skyddad transport, insamlingen är verifierad med en spårbar testhändelse, och skyddet av loggkedjan är dokumenterat med åtkomst, lagringstid och beteende vid onåbar mottagare. (Boiler Room: Zonuppdraget)

Det här är elev-24:s (Stef, Serverzon) del. Teamkamraternas material ligger i `docs/vecka_05/elev-NN/`.

| Fil | Innehåll | Status |
|---|---|---|
| [loggkallekarta.md](loggkallekarta.md) | Loggkällor på elev-24 med klistrade exempelrader | Ifylld och verifierad 2/11 |
| [fem-fragor-och-urval.md](fem-fragor-och-urval.md) | Fem frågor, urval och strukna källor | Utkast att granska med teamet |
| [loggstrategi.md](loggstrategi.md) | Loggstrategi version 1 | Utkast |
| [skyddsbeskrivning.md](skyddsbeskrivning.md) | Skyddet av loggkedjan (fyra rubriker och ett scenario) | Ifylld med belägg och kötest 2/11. Central lagringstid och fylld kö är inte kontrollerade |
| [verifieringsanteckning.md](verifieringsanteckning.md) | Testhändelser och var de hittades centralt | Klar 2/11 och omverifierad 9/11 (testhändelse och brandväggsrad över TLS) |
| `90-logg.conf`, `50-root-cmd.rules`, `ca.pem`, `ladda-logg.sh` | Konfigurationen som körs på elev-24 | Körda på elev-24 2/11 08:07Z (RC=0) |

Regelverket för elev-24 ([elev-24-zon.nft](../../vecka_04/elev-24/elev-24-zon.nft)) släpper D5 på tcp/6514 i stället för 514.

## Ordning på servern

Ordningen följer studieguiden: tid först, flöde sedan, vidarebefordran därefter, testhändelse sist.

```
# från repot på din dator
scp -r docs/vecka_04/elev-24 lab:           # mappnamnet måste vara elev-24 (test.sh läser det)
scp -r docs/vecka_05/elev-24 lab:logg

# på servern, två SSH-sessioner öppna
chronyc tracking ; timedatectl              # 1. tid
cd ~/elev-24 && sudo bash ladda-zon.sh      # 2. flöde: D5 på tcp/6514 (nödbroms 5 min)
#    ny session via jump fungerar? -> sudo systemctl stop nodbroms.timer
bash test.sh testfall.csv                   #    D5-till ska bli oppen, D5-nek-klartext tyst
cd ~/logg && sudo bash ladda-logg.sh        # 3. TLS-vidarebefordran och auditd, 4. testhändelse
```

På jump:
- `loggsök <id>`: kontrollera att kanalen är TLS och att värdnamn och tid stämmer. Fyll i [verifieringsanteckning.md](verifieringsanteckning.md).

CA-certifikatet ligger i mappen. Studieguiden hämtar det med `curl http://log.sec.chas-lab.dev/ca.pem`, men regelverket nekar tcp/80 mot log (testfallet `D7-nek`). `ladda-logg.sh` kontrollerar fingeravtrycket innan certet installeras.

## Klart när (elev-24)

- [x] `loggsök` visar en testhändelse över TLS med rätt värdnamn och tid (2/11 och 9/11)
- [x] sshd/sudo, paketfiltret och auditd (rätt auid) kommer fram centralt (2/11, paketfiltret igen 9/11)
- [x] Kön håller vid avbrott och omstart (kötest 2/11, U5.2)
- [x] `test.sh` är omkörd och testprotokollet och spårbarhetslistan är uppdaterade (D5 verifierad 2/11)
- [ ] Granskat av en teamkamrat och mergat till `main`
