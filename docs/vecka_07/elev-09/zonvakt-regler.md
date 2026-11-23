# Regler i zonvakt.te – varför de behövs

## Regler som lades till

| Nr | Regel | Varför |
|---|---|---|
| 1 | `allow zonvakt_t self:tcp_socket { accept bind create getattr listen setopt read write };` | Zonvakt skapar en socket, ställer in den, binder den till port 7509, lyssnar och accepterar anslutningar. Den läser det man skickar och skriver tillbaka svaret. `read write` lades till efter att zonvakt inte kunde svara (sendall, Permission denied). |
| 2 | `corenet_tcp_bind_generic_node(zonvakt_t)` | Zonvakt behöver binda till serverns adress för att kunna lyssna och göra sitt jobb. SELinux kollar både adressen och porten separat, och utan den här regeln får zonvakt inte lyssna alls. |
| 3 | `corenet_tcp_bind_generic_port(zonvakt_t)` | Behövs för att zonvakt ska kunna binda port 7509. Men "generic" betyder att den får binda vilken oreserverad port som helst, inte bara 7509, så den är bredare än den behöver vara. |
| 4 | `corecmd_mmap_bin_files(zonvakt_t)` | Behövs för att zonvakt ska få läsa och köra program i /usr/bin, som Python-tolken, för att kunna köra Python-skriptet. |
| 5 | `auth_read_passwd_file(zonvakt_t)` | Behövs för att Python vid start slår upp vilken användare zonvakt kör som (uid 0 = root). Utan den kraschar zonvakt redan vid start. Filen innehåller bara användarnamn, inga lösenord. |
| 6 | `sssd_read_public_files(zonvakt_t)` | Samma uppslag som regel 5, fast via sssd. Zonvakt får läsa de allmänna användaruppgifterna. |
| 7 | `sssd_search_lib(zonvakt_t)` | Samma uppslag som regel 5, fast via sssd. Zonvakt får söka i sssd:s mapp. |

## Förslag från audit2allow som inte togs med

| Regel | Varför inte |
|---|---|
| `files_manage_etc_files(zonvakt_t)` | Låter zonvakt ändra filer i /etc. Det är själva överträdelsen och ska inte gå. |
| `auth_etc_filetrans_shadow(zonvakt_t)` | Låter zonvakt skapa filer i /etc. Kom med för att overtrad försökte skriva där. Ska stoppas. |
| `corecmd_exec_bin(zonvakt_t)` | Låter zonvakt starta vilket program som helst i /usr/bin. Behövs inte, regel 4 räcker för Python. |
