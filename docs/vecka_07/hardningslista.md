# Härdningslista – elev-09

| Nr | Åtgärd | Motivering | Förväntad effekt | Verifiering | Skript? |
|---|---|---|---|---|---|
| 1 | SELinux i enforcing, nu och efter omstart | Utan enforcing stoppas inget. Zonvakt körde som root och kunde skriva i /etc. I permissive hade det bara loggats | Överträdelser nekas (Permission denied) och loggas som AVC | `sestatus`: Current mode och Mode from config file = enforcing | Ja |
