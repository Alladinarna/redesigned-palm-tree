# Detektioner – nedbrytningar vecka 6 (elev-09)

Här är mina fyra händelser nedbrutna. Varje har loggkälla, fält, faktiska
värden från riktiga poster i Wazuh, och ett gränsfall som inte ska träffa.
Det här är grunden för detektionerna (milstolpe 6).

## Händelse 1 – Brute force mot SSH

- **Loggkälla:** sshd (authpriv)
- **Fält:** rule.id, rule.groups, data.srcip, data.srcuser, rule.level
- **Faktiska värden** (regel 5712, korrelationen):
  - rule.id: 5712, rule.level: 10
  - rule.groups: authentication_failed
  - data.srcip: 10.40.3.86, 10.40.1.219, 172.20.1.10 (tre olika angreppskällor)
  - data.srcuser: admin, ubuntu, admin97 (klassiska angreppskonton)
  - rule.mitre.id: T1110 (Brute Force)
- **Gränsfall (ska inte träffa):** misslyckade inloggningar från jump
  (172.20.1.2) mot kontot student. Det är min egen inloggning. Känd källa,
  så det ska inte larma.

## Händelse 2 – Zonöverträdelse

- **Loggkälla:** paketfiltret (kern / nftables), predecoder.program_name: kernel
- **Fält:** data.action, data.srcip, data.dstip, data.dstport, data.protocol
- **Faktiska värden:**
  - data.action: ZON-IN-DROP
  - data.srcip: 172.20.1.2 (jump)
  - data.dstip: 172.20.1.109 (elev-09)
  - data.dstport: 80
  - data.protocol: TCP
- **Gränsfall (ska inte träffa):** tillåten trafik enligt flödestabellen,
  t.ex. jump → SSH (port 22). Den släpps igenom. Den ger ingen drop,
  så inget larm.

## Händelse 3 – Kommando som körs som root

- **Loggkälla:** sudo (authpriv), predecoder.program_name: sudo
- **Fält:** data.srcuser, data.dstuser, data.command, rule.id
- **Faktiska värden:**
  - rule.id: 5402 ("Successful sudo to ROOT executed")
  - data.srcuser: student
  - data.dstuser: root
  - data.command: /usr/bin/systemctl restart chronyd
  - rule.mitre.id: T1548.003 (Privilege Escalation)
- **Gränsfall (ska inte träffa):** ett cron-jobb som körs som root
  (CROND (root) CMD). Det körs som root, men det är automatiskt. Det är
  ingen inloggad person som eskalerar. Så det ska inte larma.

## Händelse 4 – Nytt användarkonto skapat

- **Loggkälla:** useradd / adduser, predecoder.program_name: useradd
- **Fält:** data.dstuser, data.uid, data.home, data.shell, rule.id, rule.mitre.id
- **Faktiska värden:**
  - rule.id: 5902 ("New user added to the system"), rule.level: 8
  - data.dstuser: test46 (det nya kontot)
  - data.uid: 1001
  - data.home: /home/test46
  - data.shell: /bin/bash
  - rule.mitre.id: T1136 (Create Account / Persistence)
- **Gränsfall (ska inte träffa):** ett tjänstekonto som skapas av en
  paketinstallation. Det får oftast ett system-uid under 1000. Sånt ska
  inte larma. Därför kollar detektionen på data.uid – bara konton med
  uid 1000 eller högre är intressanta (test46 hade 1001).