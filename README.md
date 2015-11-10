# luci2-ffwizard
Freifunk Wizard für luci2 rpcd

- Aufruf des Wizard durch den Benutzer
 Eingabe der IP Adressen, Hostname
 Auswahl der Mesh Schnitstellen
 Auswahl der Funkfrequenz
 
- Aufruf des Wizard  via rpcd ```ubus call luci2.system "init_action" '{"name":"ffwizard","action":"restart"}'```

- Aufruf des Wizard auf der console zum debugen
```
logread -f > /tmp/system.log &
uci set ffwizard.ffwizard.enabled='1'
uci commit
/etc/init.d/ffwizard restart
grep ffwizard /tmp/system.log
```

 Die Scripte in ```/etc/ffwizard.d werden von``` ```/usr/sbin/ffwizard``` Alphanumerisch ausgeführt
 Die Eingaben aus dem luci2 Wizard werden von den Scripten aus uci ffwizard gelesen, verarbeitet
 und in die uci system config (system,wireless,network,olsr,...) zurück geschrieben.
 Anschliesend werden die geänderten Dinste neugeladen oder Router neugestartet.

- OpenWRT Feed
 ``ècho 'src-git luci2_ffwizard git://github.com/stargieg/luci2-ffwizard.git' >> feeds.conf```
 ```scripts/feeds update luci2_ffwizard```
 ```scripts/feeds install luci2-ffwizard```
 