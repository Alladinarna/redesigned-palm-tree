# Metodbilaga - härdningsrapport elev-46

## 1. Underlag som matades in: härdningslistan, sestatus, semodule -l, ps eZ, verifiera-hardning, zonvakt.te och hardning.conf, inga kännsliga värden behövde markeras.

## 2. Prompt, ordagrant

## 3. Råsvar, oredigerat

## 4. Rättelselogg – en rad per ändrat påstående

| Påst. nr | Påstående (kort) | Dom | Kommando som avgjorde | Faktiskt utfall | Feltyp | Ändrat till |
|---|---|---|---|---|---|---|
| P46 | Att zonvakt bara ska få göra det policyn tillåter- lyssna på sin port, svara och skriva i sin egen logg.  | fel | cat ~/policy/zonvakt.te | Policyn tillåter zonvakt att faktiskt läsa filer i /etc, läsa /etc/passwd, köra program i /usr/bin, läsa sssd cache och lyssna på valfri oresarverad port inte bara 7546| Fel i eget underlag, ingen av AI feltyperna passar in, AIn återgav min härdningslista korrekt, men listan var fel. | Zonvakt får lyssna på valfri oresarverad port, svara, skriva i sin egen logg, läsa i /etc och /etc/passwd och köra python3. Den får inte skriva i /etc. Begränsning till enbart port 7546 återstår(U7.6).|

## 5. Utelämningslista – 
**zon.nft**- Filen innehåller adresserna till jump, ctf, loggservern och appservern och tillsammans visar de hur nätet är uppbyggt. Att ge det till en extern tjänst betyder att man lämnar ut en karta över miljön, med maskering så skulle det inte bli mycket kvar som inte skulle varit omaskerat o då finns det inte så mycket som AI kan använda ändå.

**sshd_config**- studieguiden säger att man aldrig ska mata in hela autentiseringskonfigurationer. Dessutom är SSH-raderna 1 och 2 inte genomförda än så det finns inget att dokumentera om dem än.

**zon.conf**- Den hör till ctf U7.2 och är inte en härdningsåtgärd av mig.
