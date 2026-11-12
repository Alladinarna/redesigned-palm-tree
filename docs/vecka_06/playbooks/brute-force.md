# Playbook: brute force (rule.id 5712)

## 1. Förberedelse
- Se till att detektionen 5712 är igång (den korrelerar ihop 8 misslyckade inloggningar på 2 minuter från samma källa).
- Ha Wazuh Discover uppe (wazuh-alerts-*) och ha koll på hur mycket misslyckade inloggningar som är normalt, annars är det svårt att veta vad som sticker ut.

## 2. Detektion & analys
- Sök `rule.id: 5712` i wazuh-alerts-* och dra tiden till när larmet kom.
- Kolla `data.srcip` (varifrån det kom) och `data.srcuser` (vilka konton de försökte på).
- Sök sen `data.srcip: <källan>` utan värdfilter, så ser du om samma källa gav sig på fler servrar än din.
- Kolla om det följdes av en lyckad inloggning: sök `rule.id: 40112` eller "Accepted" från samma källa i samma fönster. Gjorde det det, så är det inte bara ett försök längre – då kom någon faktiskt in.

## 3. Inneslutning, utrotning & återställning
- Om allt bara var misslyckade försök: blockera käll-IP i brandväggen om den är extern eller okänd. Är det en intern maskin, ta reda på vem som satt på den.
- Om det följdes av en lyckad inloggning: hoppa till playbook 40112 – spärra kontot och tvinga fram ett lösenordsbyte.

## 4. Efterarbete
- Skriv upp i triageloggen: varifrån det kom, vilka konton, om det lyckades, och vad du gjorde.
- Var det ett falsklarm (typ ett eget test), notera skälet så nästa person slipper gräva i samma sak igen.

## Eskalera / avfärda
- Eskalera om brute forcen följdes av en lyckad inloggning, eller om den kom från en okänd extern källa. Skicka vidare till [incidentansvarig hos er] med käll-IP, konton, tidsfönster och träfflistan från Wazuh.
- Avfärda om alla försök misslyckades och källan är en känd intern maskin med en förklaring. Skriv skälet i triageloggen.
