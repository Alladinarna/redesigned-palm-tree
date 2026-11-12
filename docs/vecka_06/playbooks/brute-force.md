# Playbook: brute force (rule.id 5712)

## 1. Förberedelse
- Kolla att detektionen 5712 är aktiv i Alerting (monitorn igång, rätt tidsfönster).
- Ha Wazuh Discover uppe (wazuh-alerts-*) och ha koll på normalbilden för misslyckade inloggningar.

## 2. Detektion & analys
- Sök `rule.id: 5712` i wazuh-alerts-* och dra tiden till när larmet kom.
- Kolla `data.srcip` (källan) och `data.srcuser` (vilka konton de försökte på).
- Sök `data.srcip: <källan>` utan värdfilter – slog samma källa mot fler servrar?
- Kolla om det följdes av en lyckad inloggning: sök `rule.id: 40112` eller "Accepted" från samma källa i samma fönster. Finns det, så kom nån faktiskt in.
- Jämför tiden med teamets testlogg – var det ett planerat test?

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
- Eskalera om brute forcen följdes av en lyckad inloggning, eller kom från en okänd extern källa. Till incident responder med käll-IP, konton, tidsfönster och träfflistan från Wazuh.
- Avfärda om alla försök misslyckades och källan är en känd intern maskin med en förklaring (t.ex. ett test i testloggen). Skriv skälet i triageloggen.
