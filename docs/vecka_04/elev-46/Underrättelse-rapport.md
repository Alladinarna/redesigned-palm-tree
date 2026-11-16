
## Underrättelserapport: eMudhra Intermediate CA Compromise
21 oktober 2026

## Sammanfattning
Åtta mellanliggande certifikat från certifikatutfärdaren eMudhra hade så svaga privata nycklar att vem som helst kunde räkna fram dem. De stora webbläsarna och operativsystemen har blockerat certifikaten, men andra program kan vara sårbara tills de uppdateras.

## Vad hände?
Alla åtta certifikaten använde P-384-nycklar som skapades i april 2025, med värden under 256. Det räckte alltså att testa 256 möjliga tal för att hitta nyckeln. eMudhra förklarar felet med ett skript som skapade en andra uppsättning svagare nycklar med liknande namn, och som därför av misstag valdes för att signera certifikat. Upptäckaren bevisade felet genom att signera ett meddelande med var och en av de åtta nycklarna, och rapporterade det den 17 oktober. 
Bleeping Computer
bastionzero

## Påverkan
Den som har en av nycklarna kan utge sig för att vara vilken webbplats eller tjänst som helst, och därmed avlyssna eller ändra krypterad trafik. Attacken kräver att angriparen kan placera sig mellan offret och servern.

## Läge
Certifikaten har varit blockerade i Firefox och Chrome sedan den 17 oktober, i Apples enheter sedan den 19 oktober och i Microsofts plattformar sedan den 20 oktober. Inga av certifikaten finns i de offentliga certifikatloggarna, så webbläsare som kräver sådana loggar kan inte ha attackerats. Många program utanför webbläsarna kontrollerar dock inte loggarna, och det är okänt om någon har utnyttjat felet mot dem. Mozilla tar dessutom bort förtroendet för rotcertifikatet emSign ECC Root CA – G3, och omkring 30 000 certifikat behöver flyttas. 
webpronews

## Bedömning
Risken för vanliga webbläsaranvändare är låg. Webbläsarna skyddades snabbt via sina egna listor över återkallade certifikat, men många andra program läser inte sådana listor och kräver en uppdatering. Störst risk har därför system som uppdateras långsamt, som Linux-servrar, IoT-enheter och containrar.

## Rekommendation
Uppdatera webbläsare, operativsystem och certifikatpaketet (ca-certificates) på alla system. Organisationer med certifikat under emSign ECC G3 bör byta dem.

## Källor

Dennis Jackson (Mozilla), eMudhra Intermediate CA Compromise, 20 okt 2026: https://emudhra.we-have-a-problem.com/
BleepingComputer, Mozilla, Google, Apple block compromised eMudhra CA certificates: https://www.bleepingcomputer.com/news/security/mozilla-google-apple-block-compromised-emudhra-ca-certificates/
BastionZero, eMudhra Revokes Eight Weak CA Certificates: https://www.bastionzero.com/blog/emudhra-revokes-weak-ca-certificates-browsers-block
WebProNews, Weak Keys Compromise Eight eMudhra Certificates as Mozilla and Chrome Move to Drop an emSign Root: https://www.webpronews.com/emudhra-intermediate-certificates-compromised-weak-keys/
Ars Technica, Dan Goodin, 20 okt 2026, The Internet goes on high alert after discovery of 8 compromised TLS certs.

## Utkast framtaget med Claude (AI). Källgranskning gjord av mig, Hugo Wester.
