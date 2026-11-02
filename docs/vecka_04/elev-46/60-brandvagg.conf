# /etc/rsyslog.d/60-brandvagg.conf – elev-46
# Skickar kärnans loggar (där ZON-IN-DROP och ZON-UT-DROP hamnar) till loggservern.
# Flödestabellen: D5, min server → log 172.20.1.58, TCP 514. Klartext i vecka 4, TLS 6514 från vecka 5 (F11).
# Kön sparar loggarna på disk om loggservern inte svarar och försöker igen tills den gör det.
kern.* action(type="omfwd" target="172.20.1.58" port="514" protocol="tcp"
        queue.type="LinkedList" queue.filename="fwd_kern"
        queue.saveOnShutdown="on" action.resumeRetryCount="-1")
