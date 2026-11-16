# Playbook: brute force (rule.id 5712, 5760, 5763)

Larmet betyder: många misslyckade inloggningar från samma källa på kort tid – någon försöker gissa sig in (brute force). Misslyckas allt är det ett försök; följs det av en lyckad inloggning är någon faktiskt inne.

När: starta när brute force-monitorn larmar. Börja i Alerting → Alerts för att se larmets tid och server, gå sen till Discover för analysen. Håll tidsfönstret runt larmet genom hela analysen (inte 24 h). Testloggen är i UTC, Wazuh visar svensk tid (+1 h).

## 1. Förberedelse
- Kolla att brute force-monitorn är aktiv i Alerting (monitorn igång, rätt tidsfönster).
- Ha Wazuh Discover uppe (wazuh-alerts-*) och ha koll på normalbilden för misslyckade inloggningar.
- Ha teamets testlogg öppen (ligger i repot) – där står planerade tester med tid, källa och konto.

## 2. Detektion & analys
- Sök `rule.id: 5712 or rule.id: 5760 or rule.id: 5763` i wazuh-alerts-* och dra tiden till när larmet kom.
- Kolla `data.srcip` (källan) och `data.srcuser` (vilka konton de försökte på).
- Sök `data.srcip: <källan>` utan värdfilter, men håll tiden runt larmet – slog samma källa mot fler servrar?
- Kolla om det följdes av en lyckad inloggning: sök `rule.id: 40112` eller "Accepted" från samma källa i samma fönster. Finns det, så kom nån faktiskt in.
- Jämför tiden med teamets testlogg. Finns en rad med samma tid och källa → planerat test. Hittar du ingen matchande rad → behandla det som skarpt.

## 3. Inneslutning, utrotning & återställning
- Bara misslyckade försök från en extern/okänd källa → blockera käll-IP i brandväggen:
  `sudo nft insert rule inet zon in ip saddr <käll-IP> drop`
  (körningsändring – lägg in raden i zon.nft om blockeringen ska vara kvar efter omstart)
- Intern källa → ta reda på vem som satt på maskinen innan du blockerar.
- Om det följdes av en lyckad inloggning → spärra kontot direkt:
  `sudo usermod -L <kontot>` (låser lösenordet)
  `sudo pkill -KILL -u <kontot>` (avslutar kontots sessioner)
  `sudo passwd -e <kontot>` (tvingar lösenordsbyte vid nästa inloggning)
- Säkra loggposterna (export eller skärmdump) innan nåt tas bort.

## 4. Efterarbete
- Skriv upp i triageloggen: källa, konton, om det lyckades, och vilken åtgärd.
- Var det ett falsklarm (eget test), notera skälet och tiden från testloggen.
- Fundera på om tröskeln behöver justeras om det mest var brus.

## Eskalera / avfärda
- Eskalera om brute forcen följdes av en lyckad inloggning, kom från en okänd extern källa, eller om ingen rad i testloggen matchar. Till incident responder med käll-IP, konton, tidsfönster och träfflistan från Wazuh.
- Avfärda om alla försök misslyckades, källan är en känd intern maskin, och det finns en matchande rad i testloggen. Skriv skälet i triageloggen.

Korstestad 2026-11-12 (Hugo följde playbooken, Gabriel antecknade). Rättat efter korstestet: startrad tillagd (börja i Alerting → Alerts), tidsfönstret runt larmet förtydligat i sökningarna, vad man gör när testloggen inte matchar (behandla som skarpt), testloggens plats angiven, "Larmet betyder" tillagt, 5760/5763 tillagda så brute force mot riktiga konton också täcks.
