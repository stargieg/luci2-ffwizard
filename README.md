# luci2-ffwizard
Freifunk Wizard für luci2 rpcd

- Aufruf des Wizard durch den Benutzer
 Eingabe der IP Adressen, Hostname
 Auswahl der Mesh Schnitstellen
 Auswahl der Funkfrequenz
 
- Aufruf des Wizard  via rpcd 
```ubus call uci "reload_config"```

- Aufruf des Wizard auf der console zum debugen
```
logread -f > /tmp/system.log &
uci set ffwizard.ffwizard.enabled='1'
uci commit
ubus call uci "reload_config"
grep ffwizard /tmp/system.log
```

 Die Scripte in /etc/ffwizard.d werden von /usr/sbin/ffwizard Alphanumerisch ausgeführt
 Die Eingaben aus dem Wizard werden von den Scripten aus /etc/config/ffwizard gelesen, verarbeitet
 und in die uci system config (system,wireless,network,olsr,...) zurück geschrieben.
 Anschliesend werden die geänderten Dienste durch procd service_triggers neugeladen.

```/etc/init.d/ffwizard```
Valiedierung der ffwizard Konfiguration und start des Wizards mittels procd.
Procd überwacht änderungen der Wizard Konfiguration.

```/etc/init.d/ffwizard_autoconf```
Valiedierung der ffwizard_autoconf Konfiguration und start der Automatischen Konfiguration mittels procd.
Procd überwacht änderungen der Konfiguration.

```/usr/sbin/ffwizard_autoconf```
Die Wlankonfiguration wird auf die standart Werte zurückgesetzt. Danach wird nach 802.11s Netzen gesucht.

```/etc/ffwizard.d/10-system.sh```
Wenn der Hostname OpenWrt ist wird eine Zufalsszahl an den Hostnamen angehangen.
Geo daten und Zeitzone werden eingestellt

```/etc/ffwizard.d/20-system.sh```
Die Wlan- und die Netzwerkeinstellungen

```/etc/ffwizard.d/30-batadv.sh```
B.A.T.M.A.N Mesh Konfiguration

```/etc/ffwizard.d/30-olsrd.ipv4.sh```
Legacy olsr1 ipv4

```/etc/ffwizard.d/30-olsrd.ipv4.sh```
Legacy olsr1 ipv6

```/etc/ffwizard.d/31-olsrd2.ipv6.sh```
Legacy olsr2 ipv6 Mesh Konfiguration

```/etc/ffwizard.d/40-firewall.sh```
Firewall Konfiguration

```/etc/ffwizard.d/50-uhttpd.sh```
Webserver Konfiguration mit TLS Cert commonname=Hostname

```/etc/ffwizard.d/60-dhcp.sh```
dnsmasq und odhcpd Konfiguration für ipv4 und ipv6


Für den Wizard und die Autokonfiguration gibt es 3 Verschieden Frontends.

- Das in Lua geschriebene LuCI
```luasrc```

- Das in JS geschriebene und auf jquery basierende luci2
```/www/luci2```

- Das in JS geschriebene und auf angular basierende luci-ng
```/www/luci-ng```

Installation der OpenWRT Feed's
 ```echo 'src-git luci2_ffwizard git://github.com/stargieg/luci2-ffwizard.git' >> feeds.conf```
 ```scripts/feeds update luci2_ffwizard```
 ```scripts/feeds install luci2_ffwizard```

