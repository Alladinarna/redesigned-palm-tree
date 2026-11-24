Mina fem visningsfilter

1. tcp.flags.syn==1 and tcp.flags.ack==0
Hittar: nya anslutningsförsök, SYN utan ACK. Många från en källa mot många portar är skanning.
Hjälper med: U8.2 och U8.4, hitta skanningen.

2. tcp.port == 22
Hittar: all trafik på port 22 i TCP, åt båda hållen.
Hjälper med: U8.2 och U8.3, hitta brute force och lateral rörelse med SSH.

3. tcp.flags.reset==1
Hittar: RST, när värden svarar att ingen lyssnar på porten, "connection refused".
Hjälper med: U8.4, hitta den trasiga tjänsten som får RST om och om igen.

4. dns.flags.response==0 and dns.qry.name.len > 25
Hittar: DNS-frågor där namnet är längre än 25 tecken.
Hjälper med: U8.1, hitta DNS-tunneln med flaggan.

5. dns and tcp
Hittar: DNS som går över TCP. DNS går normalt över UDP, så det kan vara ett stort svar.
Hjälper med: hitta tunnling eller manipulerade svar.
