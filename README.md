# luci2-ffwizard
Freifunk Wizard für luci2 rpcd

- Aufruf des Wizard durch den Benutzer
 Eingabe der IP Adressen, Hostname
 Auswahl der Mesh Schnitstellen
 Auswahl der Funkfrequenz
 
- Aufruf des Wizard  via rpcd ```ubus call uci "reload_config"```

- Aufruf des Wizard auf der console zum debugen
```
logread -f > /tmp/system.log &
uci set ffwizard.ffwizard.enabled='1'
uci commit
ubus call uci "reload_config"
grep ffwizard /tmp/system.log
```

 Die Scripte in ```/etc/ffwizard.d werden von``` ```/usr/sbin/ffwizard``` Alphanumerisch ausgeführt
 Die Eingaben aus dem luci2 Wizard werden von den Scripten aus uci ffwizard gelesen, verarbeitet
 und in die uci system config (system,wireless,network,olsr,...) zurück geschrieben.
 Anschliesend werden die geänderten Dienste durch procd service_triggers neugeladen.
 


- OpenWRT Feed
 ``ècho 'src-git luci2_ffwizard git://github.com/stargieg/luci2-ffwizard.git' >> feeds.conf```
 ```scripts/feeds update luci2_ffwizard```
 ```scripts/feeds install luci2-ffwizard```
 
