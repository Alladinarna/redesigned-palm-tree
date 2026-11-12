# Molnbrandvägg itsx26-elev-09

```
  1  out tcp  443         0.0.0.0/0            F6 webb https ut (även D7 dnf)
  2  out tcp  80          0.0.0.0/0            F6 webb http ut
  3  out udp  123         213.239.239.164/32   D4 NTP ntp.hetzner.com
  4  out udp  123         213.239.239.165/32   D4 NTP ntp.hetzner.com
  5  out udp  123         213.239.239.166/32   D4 NTP ntp.hetzner.com

Utgående: bara det som står i ut-reglerna (implicit neka).
```