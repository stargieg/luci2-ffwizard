# luci2-ffwizard
Freifunk Wizard für luci2 rpcd

- Hardwareerkennung in ```/etc/uci-defaults/ffwizard```
```
ether_ifaces="lan wan" #TODO
for interface in $ether_ifaces;do
uci batch <<-EOF >/dev/null 2>/dev/null
	add ffwizard $interface=interface
	set ffwizard.$interface.enabled=0
	set ffwizard.$interface.olsr_mesh=0
	set ffwizard.$interface.bat_mesh=0
	commit ffwizard
EOF
done
```
```
wifi_ifaces="radio0 radio1" #TODO
for interface in $wifi_ifaces;do
uci batch <<-EOF >/dev/null 2>/dev/null
	add ffwizard $interface=interface
	set ffwizard.$interface.enabled=0
	set ffwizard.$interface.olsr_mesh=0
	set ffwizard.$interface.bat_mesh=0
	set ffwizard.$interface.vap=0
	commit ffwizard
EOF
done
```
- Aufruf des Wizard durch den Benutzer
 Eingabe der IP Adressen, Hostname
 Auswahl der Mesh Schnitstellen
 Auswahl der Funkfrequenz
 
- Aufruf der Wizard scripte durch ucitrack

 Die Scripte in /etc/ffwizard.d werden Alphanumerisch ausgeführt
 Start über ein init script.
 via rpcd ```ubus call luci2.system "init_action" '{"name":"ffwizard","action":"restart"}'```
 ```/etc/config/ffwizard``` feststellt.
 Die eingaben aus dem Wizard werden von den Scripten aus uci ffwizard gelesen, verarbeitet
 und in die uci system config (system,wireless,network,olsr,...) geschrieben
