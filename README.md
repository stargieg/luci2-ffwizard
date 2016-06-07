# luci2-ffwizard
Freifunk Wizard für luci2 rpcd

```
/etc/uci-defaults/ffwizard
```
 Wenn der Hostname OpenWrt ist wird eine Zufallszahl an den Hostnamen an gehangen.  
 IPv6 fähiegen NTP Server setzen.  
 Webserver Konfiguration mit TLS Cert commonname=Hostname  
 Hostname frei.funk=ula_prefix  
 lan ipaddr "192.168.42.1"  
 Resolve /p2p/::1#3535 von Kadnode IPv6 als Ersatz für den olsr namservice  

```
/etc/uci-defaults/ffwizard_fw
```
 Setzen der Firewall grundeinstellungen  


- Aufruf des Wizard durch den Benutzer
 Eingabe der IP Adressen, Hostname  
 Auswahl der Mesh Schnittellen  
 Auswahl der Funkfrequenz  
 
- Aufruf des Wizard  via rpcd 
```
ubus call uci "reload_config"
```

- Aufruf des Wizard auf der Konsole zum Debuggen
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
 Anschließend werden die geänderten Dienste durch procd service_triggers neu geladen.  

```
/etc/init.d/ffwizard
```
Validierung der ffwizard Konfiguration und Start des Wizards mittels procd.  
Procd überwacht Änderungen der Wizard Konfiguration.  

```
/etc/init.d/ffwizard_autoconf
```
Validierung der ffwizard_autoconf Konfiguration und start der Automatischen Konfiguration mittels procd.  
Procd überwacht Änderungen der Konfiguration.  

```
/usr/sbin/ffwizard_autoconf
```
Die Wlan- Konfiguration wird auf die Standard Werte zurückgesetzt. Danach wird nach 802.11s Netzen gesucht.  

```
/etc/ffwizard.d/10-system.sh
```
Wenn der Hostname OpenWrt ist wird eine Zufallszahl an den Hostnamen an gehangen.  
Geodaten und Zeitzone werden eingestellt  

```
/etc/ffwizard.d/20-network.sh
```
Die Wlan- und die Netzwerkeinstellungen  

```
/etc/ffwizard.d/30-batadv.sh
```
B.A.T.M.A.N Mesh Konfiguration  

```
/etc/ffwizard.d/30-olsrd.ipv4.sh
```
Legacy olsr1 ipv4  

```
/etc/ffwizard.d/30-olsrd.ipv6.sh
```
Legacy olsr1 ipv6  

```
/etc/ffwizard.d/31-olsrd2.ipv6.sh
```
olsr2 ipv6 Mesh Konfiguration  

```
/etc/ffwizard.d/40-firewall.sh
```
Firewall Konfiguration  

```
/etc/ffwizard.d/50-uhttpd.sh
```
Webserver Konfiguration mit TLS Cert commonname=Hostname  

```
/etc/ffwizard.d/60-dhcp.sh
```
dnsmasqd und odhcpd Konfiguration für ipv4 und ipv6  


Für den Wizard und die Autokonfiguration gibt es 3 Verschieden Frontends.

- Das in Lua geschriebene LuCI
```
luasrc
```

- Das in JS geschriebene und auf jquery basierende luci2
```
/www/luci2
```

- Das in JS geschriebene und auf angular basierende luci-ng
```
/www/luci-ng
```

Installation der OpenWRT Feed's  
```
echo 'src-git luci2_ffwizard git://github.com/stargieg/luci2-ffwizard.git' >> feeds.conf
```
```
scripts/feeds update luci2_ffwizard
```
```
scripts/feeds install luci2_ffwizard
```

