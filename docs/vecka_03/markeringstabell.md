# Markeringstabell: zonförslaget prövat mot checklistan

| Plats i zonförslaget | Kontrollfråga som faller | Var den implicita tilliten ligger | Föreslagen ändring | Vad ändringen kostar i drift |
|---|---|---|---|---|
| Loggzon (10.40.50.0/29), loggflöden från DMZ, Serverzon, Databaszon och jump på TCP 514 | 2. Måste en server visa vem den är för att nå loggservern? | Loggar skickas okrypterat, och loggservern litar på avsändaren bara för att den sitter i en tillåten zon | Byt till TCP 6514 med TLS, och verifiera avsändaren med certifikat | Certifikat måste skapas, distribueras och förnyas |
| Adminzon (jump), SSH 22 till alla interna zoner utom gästzonen | 3. Når servern bara det den behöver? | Den som tar över jump når alla servrar i sex zoner på en gång | Begränsa jump till de servrar som faktiskt administreras, och logga varje session | Fler regler att underhålla, och nya servrar måste läggas till uttryckligen |
| Adminzon (jump) → Loggzon, SSH 22 | 7. Kan vi i efterhand se vem som har loggat in, när och varifrån? | Den som tar över jump kan också logga in på loggservern och radera spåren | Separat konto för loggadministration, och loggar som bara kan läggas till men inte ändras eller raderas | Ett extra konto att hantera, och loggarna tar mer plats |
| Behörig administratör (extern) → Adminzon, SSH 22 | 4. Krävs mer än rätt nät för att få åtkomst? | Skissen säger inte vad som gör en administratör "behörig". Om bara en SSH-nyckel krävs räcker en stulen nyckel | Kräv nyckel plus MFA, och begränsa vilka källadresser som får ansluta | MFA måste sättas upp, och administratörer som jobbar hemifrån behöver en fast adress eller VPN |
| Klientzon → Serverzon, "Nödvändiga tjänster" | 3. Når servern bara det den behöver? | Hela klientzonen får nå hela serverzonen, utan angivna portar | Skriv ut exakt vilka tjänster och portar klienterna behöver, och neka resten | Måste uppdateras varje gång en ny tjänst läggs till |
| Inom varje zon, till exempel Serverzon (10.40.20.0/27) | 2. Platsen ger ingen tillit | Default deny gäller mellan zoner men inte inom dem. Servrar i samma zon når varandra fritt, och molnbrandväggen filtrerar inte det privata nätet | Mikrosegmentering med värdbrandvägg (nftables) på varje server, så att bara definierade flöden tillåts | Regler på varje server, och mer arbete vid felsökning |
| Alla servrar, säkerhetsläge | 5. Påverkar en servers säkerhetsläge om den får åtkomst? | Servrar får åtkomst oavsett patchnivå (se eMudhra: ca-certificates inte uppdaterat) | Övervaka patchnivå och flagga servrar som saknar viktiga uppdateringar | Kräver ett verktyg och någon som följer upp |

## Övrigt att rätta i skissen

- Loggpilarna från Serverzon och Databaszon saknar port. De andra säger TCP 514. Skriv samma på alla, eller TCP 6514 om ni gör ändringen i rad 1.
