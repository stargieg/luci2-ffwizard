# luci2-ffwizard
Freifunk Wizard für luci2 rpcd

- Aufruf des Wizard durch den Benutzer
 Eingabe der IP Adressen, Hostname
 Auswahl der Mesh Schnitstellen
 Auswahl der Funkfrequenz
 
- Aufruf des Wizard  via rpcd ```ubus call luci2.system "init_action" '{"name":"ffwizard","action":"restart"}'```

 Die Scripte in ```/etc/ffwizard.d werden von``` ```/usr/sbin/ffwizard``` Alphanumerisch ausgeführt
 Die Eingaben aus dem luci2 Wizard werden von den Scripten aus uci ffwizard gelesen, verarbeitet
 und in die uci system config (system,wireless,network,olsr,...) zurück geschrieben.
 Anschliesend werden die geänderten Dinste neugeladen oder Router neugestartet.
