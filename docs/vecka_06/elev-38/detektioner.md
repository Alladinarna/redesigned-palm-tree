# Detektion – elev-38 (Databaszon)

Naima, elev-38. Alla tider i UTC (Wazuh visar svensk tid, +1 h).

**Mätfönster:** normaltrafik 2026-11-11 07:06–07:37 UTC (0,5 h). Verifierat fönster 2026-11-04 23:00 UTC – 2026-11-15 19:52 UTC (≈ 261 h).

## Översikt

| Händelse | Loggkälla | Filter | Faktiska värden | Gränsfall |
|---|---|---|---|---|
| Brute force mot SSH (T1110) | sshd / sshd-session, wazuh-alerts-* | elev-38, rule.id 5710/5712/5760/5763, ≥ 5 på 5 min | 172.20.1.10, backup71, backup84 m.fl., 2026-11-15 19:25 UTC (U6.2) | Ett eller ett par felskrivna lösenord på ett konto som finns (enstaka 5760) |

## Brute force mot SSH

Monitorn **T1110 brute force mot elev-38** i Wazuh Alerting söker i `wazuh-alerts-*` varje minut. Den räknar Wazuh-reglerna för misslyckade SSH-inloggningar mot elev-38 de senaste 5 minuterna och larmar vid 5 eller fler.

- **Regler:** 5710 (användare som inte finns), 5712 (brute force mot användare som inte finns), 5760 (fel lösenord på konto som finns), 5763 (brute force mot konto som finns).
- **Varför 5760/5763:** först räknade monitorn bara 5710/5712. Teamet upptäckte på elev-09 att en brute force mot det riktiga kontot `student` då inte gav något larm (falskt negativt, se triageloggen 2026-11-12). Jag lade till 5760/5763 den 15/11.
- **Larmet betyder:** minst 5 misslyckade inloggningsförsök mot elev-38 inom 5 minuter. Det tyder på att någon försöker gissa sig in.
- **Riktig träff (framkallad):** `kontrollera U6.2 start` kl. 19:24 UTC. ctf-servern 172.20.1.10 gjorde 12 försök med påhittade användarnamn (backup71, backup84 m.fl.). Monitorn larmade, och kontrollen godkände U6.2.
- **Ska inte larma:** någon som skriver fel lösenord en eller ett par gånger.

### Brus

| Fönster | Längd | Träffar | Per timme | Larm från monitorn |
|---|---|---|---|---|
| Normaltrafik 11/11 07:06–07:37 UTC | 0,5 h | 49 | ≈ 98 | ≈ 3 (tre klungor med 8–11 försök på 30 s) – alla falsklarm |
| Verifierat fönster 5/11–15/11 | ≈ 261 h | 62 | ≈ 0,24 | 49 normaltrafik, ≈ 12 U6.2-testet, 1 träff 9/11 som inte är utredd |

Normaltrafiken ligger i min egen ström (`location: /var/log/remote/inmatat/elev-38/normal.log`). Försöken kom från minst sex olika adresser, 8–11 försök var: 10.40.1.118, 10.40.2.3, 10.40.2.5, 10.40.3.194, 10.40.3.175 m.fl. Användarnamnen var påhittade (guest, postgres, deploy).

### Falsklarmsrisk

- Monitorn räknar **alla adresser tillsammans**. Den fångar ett angrepp som sprids över flera adresser, men larmar också när flera källor gör några försök var, som i normaltrafiken. En tröskel per `data.srcip` hade gett färre falsklarm men missat ett utspritt angrepp.
- Med 5760 kan en person som skriver fel lösenord fem gånger på fem minuter ge ett larm.
- Våra egna tester och ctf-kontrollerna larmar likadant som ett riktigt angrepp. De måste stämmas av mot testloggen.
- 10.40.1.118 ligger i Serverzonen. Enligt flödestabellen får Serverzonen bara nå elev-38 på port 5432, så i verkligheten hade nftables stoppat de SSH-försöken innan de kom fram.

## Testlogg

| Tid (UTC) | Vem | Från | Mot | Vad (kommando) | Förväntat larm |
|---|---|---|---|---|---|
| 2026-11-15 19:24 | Naima | ctf (172.20.1.10) | elev-38 | `kontrollera U6.2 start` på jump, 12 försök med påhittade användare | Brute force (5710/5712) |

## Triagelogg

### Larm: T1110 brute force mot elev-38

- **Observation:** cirka 12 misslyckade SSH-inloggningar mot elev-38, 2026-11-15 19:25 UTC, rule.id 5710, data.srcip 172.20.1.10, data.srcuser backup71, backup84 m.fl. (påhittade). Monitorn larmade kort därefter.
- **Vad hände:** någon försökte gissa sig in på elev-38 med påhittade användarnamn.
- **Vad berördes:** bara elev-38. Ingen lyckad inloggning från 172.20.1.10 under försöken.
- **Vad ska göras:** avfärda. Källan är ctf-servern, och tiden stämmer med testloggen (19:24 UTC, Naima, `kontrollera U6.2 start`).
- **Att tänka på:** om ctf-servern loggar in som root med nyckel strax efteråt kopplar Wazuh ihop det till regel 40112 ("failures followed by a success"). Det är ctf-kontrollen och inget lyckat angrepp: observationerna är `Accepted publickey`, kontot root och källan 172.20.1.10.
