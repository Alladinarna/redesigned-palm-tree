# Lagerkarta – nätverkstrafik

Lagerkartan visar vad de olika TCP/IP-lagren gör och hur de syns i den nätverkstrafik jag har undersökt i Wireshark.

## 1. Applikationslagret – DNS, HTTP, SSH och NTP

**Uppgift:** Det här lagret handlar om vad kommunikationen används till.

* **DNS:** Översätter domännamn till IP-adresser.
* **HTTP:** Används för kommunikation med webbsidor.
* **SSH:** Används för säker fjärrinloggning.
* **NTP:** Används för att synkronisera tid.

**Belägg:** Jag hittade en DNS-fråga efter log.sec.chas-lab.dev och ett svar med IP-adressen 46.224.108.117. Jag hittade även en HTTP GET-förfrågan för samma domän samt SSH- och NTP-trafik.

## 2. Transportlagret – TCP och UDP

**Uppgift:** Det här lagret hanterar transporten av data och använder portar för att skilja mellan olika tjänster.

* **TCP:** Används bland annat för HTTP och SSH.
* **UDP:** Används bland annat för DNS och NTP.

**Belägg:** Jag observerade TCP-portarna 22, 80, 4444 och 9000 samt UDP-portarna 53 och 123. Ett TCP-paket till port 9000 hade RST-flaggan. Jag hittade också TCP-trafik till port 4444 med Base64-kodat innehåll som avkodades till ”lodjur stol smula kalender”. Jag har inte fastställt vad den trafiken användes till.

## 3. Internetlagret – IPv4 och ICMP

**Uppgift:** Det här lagret hanterar IP-adresser och kommunikation mellan enheter.

* **IPv4:** Används för att adressera källa och mål.
* **ICMP:** Används bland annat för ping och för att kontrollera om en enhet går att nå.

**Belägg:** Jag hittade ett ICMP Echo Request från 172.20.1.58 till 172.20.1.109. Paket 63 innehöll texten ”bricka”.

## 4. Nätverksåtkomstlagret – Ethernet och ARP

**Uppgift:** Det här lagret hanterar kommunikationen över den lokala nätverkslänken.

* **Ethernet:** Används för att transportera data i nätverksramar.
* **ARP:** Hjälper till att hitta MAC-adressen som hör till en IPv4-adress på det lokala nätverket.

**Belägg:** Jag hittade ett ARP-svar som kopplade IP-adressen 172.20.1.58 till MAC-adressen 86:00:00:a1:0b:3a. Jag använde informationen för att hitta rätt ICMP-paket.

## Exempel – SSH genom de fyra lagren

Jag hittade SSH-trafik mellan 172.20.1.2 och 172.20.1.109. Samma trafik går att beskriva genom de fyra TCP/IP-lagren.

| Lager           | Koppling till trafiken                                             |
| --------------- | ------------------------------------------------------------------ |
| Applikation     | SSH används för säker fjärrinloggning.                             |
| Transport       | TCP används på port 22.                                            |
| Internet        | IPv4-adresserna visar källan och målet.                            |
| Nätverksåtkomst | Ethernet används för att transportera data över den lokala länken. |

Exemplet visar hur lagren har olika uppgifter men samarbetar när data skickas över ett nätverk.

## Sammanfattning

Jag har undersökt nätverkstrafiken i Wireshark och kopplat protokollen till rätt TCP/IP-lager. Jag har också hittat olika trafikflöden och undersökt innehållet i vissa paket. Där jag inte har kunnat fastställa vad trafiken används till har jag hållit mig till det jag faktiskt har observerat.

