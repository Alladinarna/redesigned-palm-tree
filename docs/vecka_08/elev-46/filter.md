# Filter – elev-46 (U8.1)

Mina fem visningsfilter.

1. `tcp.flags.syn==1 && tcp.flags.ack==0`
Visar vem som öppnar anslutningar. Förväntar mig några få källor i normaltrafik. En källa mot många portar är skanning.

2. `tcp.flags.reset==1`
Visar vem som avvisar anslutningar. RST mot en stängd port är normalt, men många RST från samma mål är värt att titta på (svar på en skanning).

3. `tcp.analysis.flags`
Visar det Wireshark tycker är värt att utreda eller ser konstigt ut i TCP. En ledtråd, inte ett fynd.

4. `dns.flags.response==0`
Visar alla DNS-frågor, utan svaren.

5. `ip.addr==ADRESS && !(tcp.port==22)`
En värd minus bruset från min egen SSH-session. Obs: i scenariofångsten ligger angreppsstegen på port 22, så 22 måste granskas separat.
