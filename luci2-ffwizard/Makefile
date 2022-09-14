include $(TOPDIR)/rules.mk

PKG_NAME:=luci2-ffwizard
PKG_RELEASE:=73
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci2-ffwizard/template
  SECTION:=luci2
  CATEGORY:=LuCI2
  TITLE:=LuCI2 ffwizard module
endef

define Package/luci2-ffwizard/description
  LuCI2 Freifunk Wizard
endef

define Package/luci2-ffwizard
  $(call Package/luci2-ffwizard/template)
  MENU:=1
  EXTRA_DEPENDS:=uhttpd, uhttpd-mod-ubus, \
  dnsmasq, rpcd, rpcd-mod-file, rpcd-mod-iwinfo, rpcd-mod-rpcsys, iwinfo
endef

define Package/luci2-ffwizard/conffiles
/etc/config/ffwizard
endef

define Package/luci2-ffwizard-angular
  $(call Package/luci2-ffwizard/template)
  MENU:=1
  DEPENDS:=luci2-ffwizard
  EXTRA_DEPENDS:=luci2-ui-base
endef

define Package/luci2-ffwizard-angular/description
  LuCI2 Freifunk Wizard UI with angular
  Depends https://github.com/jow-/luci-ng
endef

define Package/luci2-ffwizard-lua
  $(call Package/luci2-ffwizard/template)
  MENU:=1
  DEPENDS:=luci2-ffwizard
  EXTRA_DEPENDS:=luci-mod-admin-full, luci-i18n-base-de, \
  luci-theme-material, luci-proto-ipv6, \
  luci-lib-json, libiwinfo-lua
endef

define Package/luci2-ffwizard-lua/description
  Freifunk Wizard UI with Luci
  Depends https://github.com/openwrt/luci
endef

define Package/luci2-ffwizard-fw
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd firewall config
  EXTRA_DEPENDS:=firewall4
endef

define Package/luci2-ffwizard-olsrd-ipv4
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd ipv4 config
  EXTRA_DEPENDS:=olsrd, olsrd-mod-jsoninfo, olsrd-mod-nameservice
endef

define Package/luci2-ffwizard-olsrd-ipv6
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd ipv6 config
  EXTRA_DEPENDS:=olsrd, olsrd-mod-jsoninfo, olsrd-mod-nameservice
endef

define Package/luci2-ffwizard-olsrv2-ipv6
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd ipv6 config
  EXTRA_DEPENDS:=oonf-init-scripts, oonf-olsrd2
endef

define Package/luci2-ffwizard-batadv
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=Batman advanced
  EXTRA_DEPENDS:=kmod-batman-adv, batctl
endef

define Package/luci2-ffwizard-kadnode
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=kadnode config
  EXTRA_DEPENDS:=kadnode, ca-bundle
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef
define Build/Configure
endef
define Build/Compile
endef

define Package/luci2-ffwizard-lua/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	rm -f /tmp/luci-indexcache
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null
fi
endef

define Package/luci2-ffwizard/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/menu.d
	$(INSTALL_DATA) files/usr/share/rpcd/menu.d/services.ffwizard.json $(1)/usr/share/rpcd/menu.d/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) files/usr/share/rpcd/acl.d/services.ffwizard.json $(1)/usr/share/rpcd/acl.d/

	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/ffwizard.d
	$(INSTALL_BIN) files/usr/sbin/ffwizard $(1)/usr/sbin/
	$(INSTALL_BIN) files/etc/ffwizard.d/10-system-js.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/ffwizard.d/20-network.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/ffwizard.d/50-uhttpd.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/ffwizard.d/60-dhcp.sh $(1)/etc/ffwizard.d/

	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d
	$(INSTALL_BIN) files/usr/sbin/ffwizard_autoconf $(1)/usr/sbin/
	$(INSTALL_BIN) files/etc/init.d/ffwizard_autoconf $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_BIN) files/etc/uci-defaults/ffwizard $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/init.d/ffwizard $(1)/etc/init.d/
	$(INSTALL_DATA) files/etc/config/ffwizard $(1)/etc/config/
endef

define Package/luci2-ffwizard-angular/install
	$(INSTALL_DIR) $(1)/www/luci-ng/controller/services
	$(INSTALL_DATA) files/www/luci-ng/controller/services/ffwizard.js $(1)/www/luci-ng/controller/services/
	$(INSTALL_DATA) files/www/luci-ng/controller/services/autoconf.js $(1)/www/luci-ng/controller/services/

	$(INSTALL_DIR) $(1)/www/luci-ng/view/services
	$(INSTALL_DATA) files/www/luci-ng/view/services/ffwizard.html $(1)/www/luci-ng/view/services/
	$(INSTALL_DATA) files/www/luci-ng/view/services/autoconf.html $(1)/www/luci-ng/view/services/
endef

define Package/luci2-ffwizard-lua/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/ffwizard
	$(INSTALL_DATA) files/www/luci-static/resources/view/ffwizard/* $(1)/www/luci-static/resources/view/ffwizard
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) files/usr/share/luci/menu.d/luci-app-ffwizard.json $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) files/usr/share/rpcd/acl.d/luci-app-ffwizard.json $(1)/usr/share/rpcd/acl.d
endef

define Package/luci2-ffwizard-fw/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/uci-defaults/ffwizard_fw $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/ffwizard.d/40-firewall.sh $(1)/etc/ffwizard.d/
endef

define Package/luci2-ffwizard-olsrd-ipv4/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d
	$(INSTALL_BIN) files/etc/ffwizard.d/30-olsrd.ipv4.sh $(1)/etc/ffwizard.d/
endef

define Package/luci2-ffwizard-olsrd-ipv6/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/usr/sbin
	$(INSTALL_BIN) files/etc/ffwizard.d/30-olsrd.ipv6.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/usr/sbin/olsrd-dyn-hna6.sh $(1)/usr/sbin/
	$(INSTALL_BIN) files/usr/sbin/olsrd-dyn-addr.sh $(1)/usr/sbin/
endef

define Package/luci2-ffwizard-olsrv2-ipv6/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/usr/sbin $(1)/etc/odhcp6c.user.d
	$(INSTALL_BIN) files/etc/ffwizard.d/31-olsrd2.ipv6.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/odhcp6c.user.d/olsrv2_lan.sh $(1)/etc/odhcp6c.user.d/
	$(INSTALL_BIN) files/usr/sbin/olsrv2-dyn-addr.sh $(1)/usr/sbin/
	$(INSTALL_BIN) files/usr/sbin/olsrneighbor2hosts.sh $(1)/usr/sbin/
	$(INSTALL_BIN) files/usr/sbin/olsrnode2hosts.sh $(1)/usr/sbin/
endef

define Package/luci2-ffwizard-batadv/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d
	$(INSTALL_BIN) files/etc/ffwizard.d/30-batadv.sh $(1)/etc/ffwizard.d/
endef

define Package/luci2-ffwizard-kadnode/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/ffwizard.d/60-kadnode.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/uci-defaults/ffwizard_kadnode $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,luci2-ffwizard))
$(eval $(call BuildPackage,luci2-ffwizard-angular))
$(eval $(call BuildPackage,luci2-ffwizard-lua))
$(eval $(call BuildPackage,luci2-ffwizard-olsrd-ipv4))
$(eval $(call BuildPackage,luci2-ffwizard-olsrd-ipv6))
$(eval $(call BuildPackage,luci2-ffwizard-olsrv2-ipv6))
$(eval $(call BuildPackage,luci2-ffwizard-batadv))
$(eval $(call BuildPackage,luci2-ffwizard-kadnode))
$(eval $(call BuildPackage,luci2-ffwizard-fw))
