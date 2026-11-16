# Underrättelserapport:

**Källa:** Ars Technica, "The internet goes on high alert after discovery of 8 compromised TLS certs"
**Datum:** [skriv in artikelns datum]

## Sammanfattning

Åtta TLS-certifikat från det indiska företaget eMudhra har nycklar som är så svaga att vem som helst kan räkna ut dem. Då kan en angripare skapa falska certifikat som webbläsare och appar litar på, för vilken sida som helst. Det är väldigt allvarligt eftersom det kan gälla miljontals enheter.

## Vad som hänt

Nycklarna var bara 3–8 bitar långa. En vanlig nyckel är cirka 384 bitar. Man upptäckte det när någon skickade ett meddelande som var signerat med en av nycklarna, och det bevisade att personen hade nyckeln. Webbläsare och många appar har redan blockerat certifikaten. Än så länge finns inga rapporter om att någon har missbrukat dem.

## Vem kan drabbas?

Både vanliga användare och företag. Oftast märker man ingenting själv. För att utnyttja felet måste angriparen ligga mitt emellan två parter och kunna läsa trafiken. Det är svårast för vanliga angripare, men lättare för den som kontrollerar ett nätverk, till exempel på ett café eller en skola. Störst risk har de som använder VPN i länder där staten kan avlyssna.

## Bedömning

**Mycket allvarligt.** Experten Filippo Valsorda säger att städningen blir större än efter Heartbleed. Det beror på att så många olika system måste uppdateras, till exempel IoT-enheter, Docker-containrar och gamla Linux-maskiner som ingen tänker på. Min säkerhet i bedömningen är medel, eftersom jag bara har läst en artikel.

## Vad bör man göra?

- Uppdatera alla maskiner så att certifikaten blockeras. Det tar tid men är inte svårt.
- Det svåra är att hitta de maskiner som är bortglömda. Man kan inte uppdatera något man inte vet finns, så gör en lista över alla servrar och enheter.
- Börja med de system som är öppna mot internet eller använder VPN.
