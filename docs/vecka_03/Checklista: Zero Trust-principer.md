# Checklista: Zero Trust-principer (NIST SP 800-207, avsnitt 2.1)

| Princip | Kontrollfråga | Bevis för ja | Vem eller vad visar det |
|---|---|---|---|
| 1. Allt är resurser | Finns varje tillgång, även jump, loggservern och ctf-servern, med i klassificeringslistan med klass? | Varje tillgång i nätet har en rad i listan med zon och klass | Klassificeringslistan i repot, jämförd med de servrar som syns i nätet |
| 2. Platsen ger ingen tillit | Måste en server visa vem den är för att nå loggservern? | Loggservern kräver TLS och verifierar avsändaren, och okända källor nekas | Loggserverns konfiguration och ett anslutningstest från en server som inte är godkänd |
| 3. Åtkomst per session, minsta behörighet | Når min server loggservern bara på tcp/6514, och ger en token bara åtkomst till just den resurs den gäller? | Anslutningar till andra portar (t.ex. 22 och 514) misslyckas, och en token för /resurs fungerar inte mot något annat | Anslutningstest med `nc` från servern, och U3.2 |
| 4. Dynamisk policy | Krävs mer än rätt nät för att få åtkomst? | Åtkomst nekas utan token och från fel enhet, och beviljas först när källa, token och tid stämmer | Anropen i U3.2 från egen server och från jump |
| 5. Ingen tillgång är betrodd i sig | Påverkar en servers säkerhetsläge, till exempel om den är uppdaterad, om den får åtkomst? | En server som saknar viktiga uppdateringar nekas eller flaggas | `dnf check-update` och en policy som kopplar patchnivå till åtkomst |
| 6. Pröva före åtkomst och pröva om | Slutar åtkomsten gälla efter en kort tid, så att man måste prövas igen? | En token äldre än två minuter nekas, och en ny prövning krävs | Svaret från resursen i U3.2 |
| 7. Samla in information | Kan vi i efterhand se vem som har loggat in eller anslutit, när och varifrån? | En inloggning jag gjorde själv går att hitta i loggen med tid, användare och källadress | `journalctl -u sshd` på servern, och loggservern |

## Svar i vår labbmiljö idag

- **2 och 3: Nej.** Min server nådde loggservern på 22, 514 och 6514.
- **4 och 6: Ja**, men bara för resursen i U3.2.
- **5: Nej.** Servrarna litade på eMudhras komprometterade certifikat, och ingenting stoppade dem för det.
- **1 och 7:** Beror på hur klassificeringslistan ser ut och vad som finns i loggarna.
