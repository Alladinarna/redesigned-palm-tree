# Säkerhetsrapport: Komprometterade nycklar för eMudhras mellanliggande CA-certifikat

**Offentliggjord:** 20 oktober 2026
**Allvarlighetsgrad:** Kritisk

## Sammanfattning

De privata nycklarna till åtta mellanliggande CA-certifikat (intermediate CA) hos eMudhra, en indisk certifikatutfärdare, har komprometterats. Certifikaten kedjar till rotcertifikat som är betrodda av Mozillas, Microsofts, Apples och Google Chromes rotprogram, och av många andra förtroendelager (trust stores) längre ned i kedjan. Den som har tillgång till någon av nycklarna kan utfärda certifikat för att utge sig för att vara vilken webbplats eller tjänst som helst.

## Grundorsak

Certifikatutfärdaren genererade de privata nycklarna felaktigt, vilket gör att de kan återskapas direkt ur de publika certifikaten. Bristen har funnits sedan certifikaten skapades i april 2025. En forskare bevisade komprometteringen genom att signera ett testmeddelande med alla åtta nycklar och rapporterade det till rotprogrammen den 17 oktober. Tekniska detaljer finns i Mozillas incidentrapport i Bugzilla (bugg 2083449).

## Vad som påverkas

- **Berörda rotcertifikat:** emSign ECC Root CA – G3 samt Comodo/Sectigo AAA Certificate Services (via Sectigos korssignaturer).
- **Webbläsare är i stort sett skyddade.** Firefox och Chrome har blockerat certifikaten sedan 17 oktober, Apple sedan 19 oktober och Microsoft sedan 20 oktober. Spärrningen sker via mekanismer som OneCRL, CRLite och CRLSets. Certifikaten finns inte i några Certificate Transparency-loggar, så webbläsare som kräver CT (Chrome, Firefox, Edge, Safari) kan inte ha attackerats.
- **Den största risken gäller klienter utanför webbläsarna.** Många verktyg kontrollerar varken spärrlistor eller Certificate Transparency. De fortsätter att lita på certifikaten tills deras medföljande förtroendelager uppdateras. Det gäller bland annat:
  - `ca-certificates`-paket i Linux och BSD
  - curl, inklusive macOS inbyggda `/usr/bin/curl`, vars `/etc/ssl/cert.pem` inte har uppdaterats
  - Programspråk och bibliotek: Go, Node.js, Python certifi/pip/uv, Rust webpki, Electron, Bun, PHP Composer, Elixir castore och Perl Mozilla::CA
- **Okänd exponering.** Det är okänt om angripare har utnyttjat bristen mot klienter utanför webbläsarna under de cirka 18 månader den funnits.

## Status för åtgärder

| Status | Programvara |
|---|---|
| **Åtgärdad** | Ubuntu, Debian, Arch, Gentoo, Fedora, Alpine, Chainguard, NSS 3.131.1, curl CA-bundle (2026-10-20), Go 1.27.3 / 1.26.10, certifi 2026.10.19, pip 26.2.2, uv 0.13.4, rustls-webpki 0.103.16, Electron 44.9.1 |
| **Väntar** | Node.js, Bun, FreeBSD |

## Rekommendationer

1. Uppdatera webbläsare och operativsystem omedelbart.
2. Uppdatera `ca-certificates`-paket och bygg om containeravbildningar.
3. Uppgradera beroenden som har egna CA-lager, till exempel certifi, webpki-roots och castore. Uppdatera även verktygskedjorna för Go och Electron.
4. Där uppdatering ännu saknas kan de två berörda rotcertifikaten tas bort manuellt enligt anvisningarna på webbplatsen. Detta rekommenderas endast för erfarna administratörer.
5. Testa era klienter mot webbplatsens testservrar. Om ni får ett certifikatfel är klienten skyddad.
6. Granska loggar från TLS-klienter utanför webbläsarna efter oväntade certifikatkedjor.

## Källor

- [eMudhra Intermediate CA Compromise](https://emudhra.we-have-a-problem.com/)
- [Mozillas incidentrapport i Bugzilla](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449)
