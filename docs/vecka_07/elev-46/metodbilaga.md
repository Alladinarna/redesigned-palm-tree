# Metodbilaga - härdningsrapport elev-46

## 1. Underlag som matades in: härdningslistan, sestatus, semodule -l, ps eZ, verifiera-hardning, zonvakt.te och hardning.conf, inga kännsliga värden behövde markeras.

## 2. Prompt, ordagrant
```
Jag ska skriva en härdningsrapport för min server, vi är ett team på 4 och min server ska representera webbserver, min server använder rocky linux 9 med SELinux, nedan finns mitt underlag.
i underlaget ingår- en härdningslista med 6st åtgärder varav 2 inte genomförda ännu, sestatus, semodule -l | grep zonvakt, ps -eZ | grep zonvakt, ett verifiera hardning script utdata, cat ~/policy/zonvakt.te, cat /etc/httpd/conf.d/hardning.conf.
skriv ett utkast till härdningsrapporten där varje åtgärd beskrivs med åtgärd effekt och hur den verifieras.
använd enbart underlaget som jag har gett här.
numrera varje påstående i rapporten så att jag kan granska dem ett och ett.
Lista eventuella luckor i underlaget i slutet.

underlag: (härdningslista.md)
```
## 3. Råsvar, oredigerat
```
Härdningsrapport – utkast: dispositionen är klar och jag börjar med omfattningen.

Utkastet till härdningsrapporten är klart. Den har 57 numrerade påståenden (P1–P57), och vart och ett hänvisar till var i underlaget det kommer ifrån. Sist finns 12 luckor (L1–L12).

Det här bör du titta på innan du lämnar in:

Effekten du skriver för zonvakt stämmer inte med din .te-fil (L6). Du skriver att den “bara” får lyssna på sin port, svara och skriva i sin logg. Men policyn ger också rätt att läsa /etc och passwd och att köra program i bin-kataloger. Den har heller ingen egen porttyp, utan använder corenet_tcp_bind_generic_port. En lärare som läser .te-filen ser det direkt. Antingen ändrar du texten eller så stramar du åt policyn.
Åtgärd 6 är bara halvt verifierad (L4). Ditt eget kriterium kräver semanage permissive -l, men den utskriften finns inte med och skriptet kontrollerar den inte.
Åtgärd 4 saknar helt belägg (L2). Rapporten kan inte påstå att systemet är uppdaterat förrän du har lagt till dnf-utskriften.

Två saker som inte står i underlaget och därför inte finns med i rapporten:

Åtgärd 2: without-password stänger redan av lösenordsinloggning för root. Det som återstår att stänga är root-inloggning med nyckel. Din motivering låter som att lösenordsgissning mot root fortfarande är möjlig, så skriv om den.
Åtgärd 1 och 2 tillsammans (L12): Kontrollera att nyckelinloggning som student fungerar innan du stänger av lösenordsinloggningen. Annars kan du låsa ute dig själv från servern.
```
själva utkastet finns oredigerat här: [AI-utkast (PDF)](<Härdningsrapport – webbserver (Rocky Linux 9) – utkast.pdf>)
## 4. Rättelselogg – en rad per ändrat påstående

| Påst. nr | Påstående (kort) | Dom | Kommando som avgjorde | Faktiskt utfall | Feltyp | Ändrat till |
|---|---|---|---|---|---|---|
| P46 | Att zonvakt bara ska få göra det policyn tillåter- lyssna på sin port, svara och skriva i sin egen logg.  | fel | cat ~/policy/zonvakt.te | Policyn tillåter zonvakt att faktiskt läsa filer i /etc, läsa /etc/passwd, köra program i /usr/bin, läsa sssd cache och lyssna på valfri oresarverad port inte bara 7546| Fel i eget underlag, ingen av AI feltyperna passar in, AIn återgav min härdningslista korrekt, men listan var fel. | Zonvakt får lyssna på valfri oresarverad port, svara, skriva i sin egen logg, läsa i /etc och /etc/passwd och köra python3. Den får inte skriva i /etc. Begränsning till enbart port 7546 återstår(U7.6).|

## 5. Utelämningslista – 
**zon.nft**- Filen innehåller adresserna till jump, ctf, loggservern och appservern och tillsammans visar de hur nätet är uppbyggt. Att ge det till en extern tjänst betyder att man lämnar ut en karta över miljön, med maskering så skulle det inte bli mycket kvar som inte skulle varit omaskerat o då finns det inte så mycket som AI kan använda ändå.

**sshd_config**- studieguiden säger att man aldrig ska mata in hela autentiseringskonfigurationer. Dessutom är SSH-raderna 1 och 2 inte genomförda än så det finns inget att dokumentera om dem än.

**zon.conf**- Den hör till ctf U7.2 och är inte en härdningsåtgärd av mig.
