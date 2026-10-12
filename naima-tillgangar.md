# Tillgångar - Vecka 1
### Name:
elev-38
### Roll:
Webbserver och SSH administration
### Intern IP:
172.20.1.138
### Tjänster och portar:
Tjänster: Apache och SSH

Portar: TCP/80 TCP/22
### Belägg: 

1. Servernamn
   
   Kommando: hostname

   Bekräftar serverns namn - elev-38

2. IP-adresser
   
   Kommando: ip -br addr

   Gav mig public och intern IP
   
   Public IP-adress: eth0: 91.107.220.202/32
   
   Intern IP-adress: eth1: 172.20.1.138/32

3. Tjänster och Portar
 
   Kommando: ss -tulpn

   Apache (httpd) lyssnar på TCP-port 80

   SSH (sshd) lyssnar på TCP-port 22
