include $(TOPDIR)/rules.mk

PKG_NAME:=luci2-ffwizard
PKG_RELEASE:=26

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
  DEPENDS:=+luci2 +px5g +uhttpd +uhttpd-mod-tls +uhttpd-mod-ubus +odhcpd \
  +dnsmasq +rpcd +rpcd-mod-file +rpcd-mod-iwinfo +rpcd-mod-rpcsys +iwinfo \
  +kadnode @IPV6
endef

define Package/luci2-ffwizard/conffiles
/etc/config/ffwizard
endef

define Package/luci2-ffwizard-fw
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard +firewall
  TITLE:=olsrd firewall config
endef

define Package/luci2-ffwizard-olsrd-ipv4
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard +olsrd +olsrd-mod-jsoninfo +olsrd-mod-nameservice
  TITLE:=olsrd ipv4 config
endef

define Package/luci2-ffwizard-olsrd-ipv6
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard +olsrd +olsrd-mod-jsoninfo +olsrd-mod-nameservice \
  TITLE:=olsrd ipv6 config
endef

define Package/luci2-ffwizard-batadv
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard +kmod-batman-adv +batctl 
  TITLE:=Batman advanced config
endef

define Build/Compile
endef

define Package/luci2-ffwizard/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/menu.d
	$(INSTALL_DATA) files/usr/share/rpcd/menu.d/services.ffwizard.json $(1)/usr/share/rpcd/menu.d/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) files/usr/share/rpcd/acl.d/services.ffwizard.json $(1)/usr/share/rpcd/acl.d/

	$(INSTALL_DIR) $(1)/www/luci2/template
	$(INSTALL_DATA) files/www/luci2/template/services.ffwizard.htm $(1)/www/luci2/template/

	$(INSTALL_DIR) $(1)/www/luci2/view
	$(INSTALL_DATA) files/www/luci2/view/services.ffwizard.js $(1)/www/luci2/view/

	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/ffwizard.d
	$(INSTALL_BIN) files/usr/sbin/ffwizard $(1)/usr/sbin/
	$(INSTALL_BIN) files/etc/ffwizard.d/10-system.sh $(1)/etc/ffwizard.d/
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

define Package/luci2-ffwizard-batadv/install
	$(INSTALL_DIR) $(1)/www/luci2/proto
	$(INSTALL_DATA) files/www/luci2/proto/batadv.js $(1)/www/luci2/proto/
	$(INSTALL_DATA) files/www/luci2/proto/batadv_vlan.js $(1)/www/luci2/proto/

	$(INSTALL_DIR) $(1)/etc/ffwizard.d
	$(INSTALL_BIN) files/etc/ffwizard.d/30-batadv.sh $(1)/etc/ffwizard.d/
endef

$(eval $(call BuildPackage,luci2-ffwizard))
$(eval $(call BuildPackage,luci2-ffwizard-olsrd-ipv4))
$(eval $(call BuildPackage,luci2-ffwizard-olsrd-ipv6))
$(eval $(call BuildPackage,luci2-ffwizard-batadv))
$(eval $(call BuildPackage,luci2-ffwizard-fw))
