# Nedbrytning av händelser – elev-38

**Mätfönster:** normaltrafik 2026-11-11 07:06–07:37 UTC (0,5 h). Verifierat fönster 2026-11-04 23:00 UTC – 2026-11-15 19:52 UTC (≈ 261 h).

## Översikt

| Händelse | Loggkälla | Filter | Faktiska värden | Gränsfall |
|---|---|---|---|---|
| 1. Brute force mot SSH | sshd-session, wazuh-alerts-* | elev-38, rule.id 5710/5712/5760/5763, ≥5 på 5 min | 172.20.1.10, oracle25, deploy65, support77 m.fl., 2026-11-15 19:25 UTC | Enstaka fel lösenord på befintligt konto (enstaka 5760) |

---

## Kommentarer

### 1. Brute force mot SSH

Vi letar efter många misslyckade SSH-inloggningar mot elev-38. Raderna skrivs av programmet `sshd-session`. Wazuh har egna regler för detta: 5710/5712 för påhittade användare och 5760/5763 för konton som finns. Händelserna finns i `wazuh-alerts-*`. Monitorn heter **T1110 brute force mot elev-38** (T1110 = Brute Force i MITRE ATT&CK), körs varje minut och slår till först vid minst 5 försök inom 5 minuter.

- **Larmet betyder:** minst 5 misslyckade inloggningsförsök mot elev-38 inom 5 minuter, från en eller flera adresser, vilket tyder på ett brute force-försök.
- **Riktig träff:** ctf-servern 172.20.1.10 provade 12 påhittade användarnamn (oracle25, deploy65, support77 m.fl.) den 15/11 kl. 19:25 UTC (U6.2).
- **Framkallad:** `kontrollera U6.2 start` på jump 2026-11-15 19:24 UTC. Monitorn larmade inom ett par minuter, och kontrollen godkände U6.2.
- **Ska inte larma:** någon som skriver fel lösenord en eller ett par gånger på ett konto som finns (enstaka 5760). Fem eller fler inom 5 minuter larmar – det är ett angrepp, inte en feltryckning.
- **Falskt negativt (teamets fynd 2026-11-12):** en brute force mot det befintliga kontot student på elev-09 gav inget larm, eftersom monitorerna bara räknade 5710/5712. Jag lade till 5760 och 5763 i min monitor den 15/11.
- **Brus, normaltrafik:** 49 träffar på 0,5 h. Normaltrafiken ligger i min egen ström (`/var/log/remote/inmatat/elev-38/normal.log`). Försöken kom i tre klungor (ca 07:10, 07:18 och 07:34–07:36 UTC) med 8–11 försök på 30 sekunder, från minst sex adresser (10.40.1.118, 10.40.2.3, 10.40.2.5, 10.40.3.194, 10.40.3.175 m.fl.) och med påhittade namn som guest, postgres och deploy – monitorn hade larmat ungefär tre gånger, alla falsklarm.
- **Brus, verifierat fönster:** 62 träffar på 261 h (≈ 0,24/h). 61 är förklarade: 49 normaltrafiken och 12 U6.2. En träff den 9/11 är inte utredd (troligen ett eget felskrivet lösenord).
- **Falsklarmsrisk:** tröskeln räknar alla adresser tillsammans. Det fångar distribuerade angrepp men larmar också när flera källor gör några försök var, som i normaltrafiken. En tröskel per data.srcip hade gett färre falsklarm men missat distribuerade angrepp. Med 5760 larmar också någon som skriver fel lösenord fem gånger. Egna tester och ctf-kontroller larmar likadant som ett riktigt angrepp och måste stämmas av mot testloggen.
- **Att tänka på:** 10.40.1.118 ligger i Serverzonen. Enligt flödestabellen får Serverzonen bara nå elev-38 på port 5432 (F10), så i verkligheten hade nftables stoppat de SSH-försöken innan sshd såg dem.

---

## Testlogg

| Tid (UTC) | Vem | Från | Mot | Vad (kommando) | Förväntat larm |
|---|---|---|---|---|---|
| 2026-11-15 19:24 | Naima | ctf (172.20.1.10) | elev-38 | `kontrollera U6.2 start` på jump, 12 försök med påhittade användare | Brute force (5710/5712) |

## Triagelogg

### Larm: T1110 brute force mot elev-38

Triagerad av Naima den 16/11 enligt teamets playbook [brute-force.md](../playbooks/brute-force.md).

- **Observation:** 12 misslyckade SSH-inloggningar mot elev-38, alla 2026-11-15 19:25 UTC, rule.id 5710 ("Attempt to login using a non-existent user"), data.srcip 172.20.1.10, data.srcuser påhittade namn (oracle25, deploy65, support77 m.fl.). Monitorn larmade kort därefter.
- **Slog källan mot fler servrar?** Sökning `data.srcip: 172.20.1.10` utan värdfilter, 19:20–19:35 UTC: 12 träffar, alla mot elev-38. Inga försök mot teamets andra servrar.
- **Följdes det av en lyckad inloggning?** Sökning `rule.id: 40112 or rule.id: 5715`, 19:20–19:45 UTC: 0 träffar. Ingen kom in.
- **Vad hände:** någon försökte gissa sig in på elev-38 med påhittade användarnamn. Alla försök misslyckades.
- **Vad berördes:** bara elev-38. Inga konton påverkades, eftersom användarnamnen inte finns.
- **Vad ska göras:** avfärda. Källan är ctf-servern (172.20.1.10), en känd intern källa. Alla försök misslyckades, och tiden stämmer med testloggen (19:24 UTC, Naima, `kontrollera U6.2 start`).
- **Att tänka på:** om ctf-servern loggar in som root med nyckel strax efter försöken kopplar Wazuh ihop det till regel 40112 ("failures followed by a success"). Det är ctf-kontrollen och inget lyckat angrepp: observationerna är `Accepted publickey`, kontot root och källan 172.20.1.10. Det hände inte den här gången.
