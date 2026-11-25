## Alla tider i UTC, från fångsten.
| Tid (UTC) | Flöde | Vad avviker | Paket | Säkerhet | Bedömning |
|---|---|---|---|---|---|
| 11:06:57 | MIN-SERVER → LOG:1514 | 38 SYN mot samma port, RST varje gång, var femte sekund. Fel port, log tar emot på 514 och 6514 | 5– | hög, jämn takt, ett mål och en port | felkonfiguration |
| 11:08:58 | ANGRIPARE → MIN-SERVER | SYN mot många portar, en gång var | 95– | hög, en källa mot många portar på kort tid | angrepp (T1046) |
| 11:09:04 | ANGRIPARE → MIN-SERVER:22 | 17 SYN mot port 22, korta sessioner, ca 1 000 byte och 0,2 sekunder | 337– | hög, många försök från samma källa | angrepp (T1110) |
| 11:09:21 | ANGRIPARE → MIN-SERVER:22 | En stor session, 5 382 byte och 17 sekunder, källport 55984 | 695 | medel, SSH är krypterat, bara storlek och längd syns. Bekräftas med loggen i U8.3 | angrepp (T1078) |
| 11:09:30 | MIN-SERVER → resolvern | 14 DNS-frågor med långa namn till samma domän, base32 i etiketterna | 706–738 | hög, avkodade till fyra ord | angrepp (T1048) |
## Berättelse

Alla tider i UTC, från fångsten.

Steg 1, 11:08:58: Angriparen skannar min server och försöker på flera olika portar (paket 95–, T1046).

Steg 2, 11:09:04: Angriparen försöker brute forca sig in via SSH på port 22 (paket 337–, T1110).

Steg 3, 11:09:21: Angriparen lyckas logga in med ett giltigt konto, en lång SSH-session (paket 695, T1078).

Steg 4, 11:09:30: Angriparen för ut data från min server via en DNS-tunnel (paket 706–738, T1048).

Lateral rörelse finns inte i min fångst. Trafiken till log på port 1514 är en felkonfiguration och inte en del av angreppet.
