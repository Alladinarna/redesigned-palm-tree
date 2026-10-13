# Tillgångsförteckning - zonuppdraget

Förteckningen beskriver labbmiljön som den ser ut idag.

## Nätet 
Labbnätet är 172.20.0.0/16 med gateway på 172.20.0.1 (eth1).
Interfacen har /32 så servrarna har inget delat länknät, all intern trafik passerar gatewayen. Mot internet går eth0 via 172.31.1.1 med publik adress satt via DHCP. IPV6 saknar adresser på interfacen men sshd och chronyd har ändå IPV6 sockets öppna.
Belägg: ip route, ip -br addr på elev-46, 11:50Z 2026-10-13.

## Infrastruktur 
| Namn | Roll | intern Adress | publik Adress | Tjänster | Belägg |
|---|---|---|---|---|---|
| jump | Bastion, enda vägen in till servrarna | 172.20.1.2 | 2.28.140.211 | SSH 22 | getent hosts 2026-10-13 |
| log | Central loggmottagare och testtjänst | 172.20.1.58 | 46.224.108.117 | TCP 514, HTTP | getent hosts 2026-10-13 |
| ctf | Tar emot och kontrollerar flaggor | 172.20.1.10 | 46.224.130.227 | HTTP | getent hosts 2026-10-13 |
| Intern gateway | Router för labbnätet | 172.20.0.1 | — | Routing | ip route 11:50Z 2026-10-13 |
| Extern gateway | Väg mot internet, DHCP | 172.31.1.1 | — | DHCP 67, routing | ip route 11:50Z 2026-10-13 |
| DNS | Namnuppslag för externa namn och kursens zon | 185.12.64.1, 185.12.64.2 | — | DNS 53 | /etc/resolv.conf 11:50Z 2026-10-13 |

## Våra servrar

Alla fyra servrar kör Rocky linux 9 med samma grunduppsättning, webbserver och SSH nås bara via jump servern. eth1 mot labbnätet och eth0 mot internet.
chronyd och dhclient körs också men är klienter, inte tjänster som andra kan nå.

| Elev | intern Adress | publik Adress | Tjänster | Belägg |
|---|---|---|---|---|
| elev-46 | 172.20.1.146/32 | 46.224.175.57/32 | SSH 22, HTTP 80 | ip -br addr, ip route, ss -tulnp, getent hosts 13:32Z 2026-10-13 |
| elev-24 | | | | |
| elev-38 | | | | |
| elev-09 | | | | |

## Observationer 
- sshd och httpd lyssnar på 0.0.0.0 alltså även publikt. SSH är ändå stängt från internet vilket betyder att filtrering sker i moln plattformens brandvägg och inte på värden.
- Varje värd har två adresser. Kortnamnet i /etc/hosts pekar på den interna medans DNS zonern sec.chas-lab.dev publicerar den publika.
- Jump har en publik adress i ett annat block (2.28.140) än log, ctf och elev-46 som alla ligger i 46.224. Vi vet inte varför.
- DNS-resolvrarna är publika adresser. DNS-trafiken lämnar labbnätet via eth0.
