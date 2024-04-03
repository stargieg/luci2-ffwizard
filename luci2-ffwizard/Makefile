include $(TOPDIR)/rules.mk

PKG_NAME:=luci2-ffwizard
PKG_RELEASE:=125
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/template
  SECTION:=luci2
  CATEGORY:=LuCI2
  TITLE:=LuCI2 ffwizard module
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  LuCI2 Freifunk Wizard
endef

define Package/$(PKG_NAME)
  $(call Package/luci2-ffwizard/template)
  MENU:=1
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/ffwizard
endef

define Package/luci-app-ffwizard
  $(call Package/luci2-ffwizard/template)
  MENU:=1
  DEPENDS:=luci2-ffwizard
  EXTRA_DEPENDS:=luci-mod-admin-full, luci-i18n-base-de, \
  luci-proto-ipv6
endef

define Package/luci-app-ffwizard/description
  Freifunk Wizard UI with Luci
  Depends https://github.com/openwrt/luci
endef

define Package/$(PKG_NAME)-fw
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd firewall config
  EXTRA_DEPENDS:=firewall4
endef

define Package/$(PKG_NAME)-olsrd-ipv4
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd ipv4 config
  EXTRA_DEPENDS:=olsrd, olsrd-mod-jsoninfo, olsrd-mod-nameservice
endef

define Package/$(PKG_NAME)-olsrd-ipv6
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd ipv6 config
  EXTRA_DEPENDS:=olsrd, olsrd-mod-jsoninfo, olsrd-mod-nameservice
endef

define Package/$(PKG_NAME)-olsrv2-ipv6
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=olsrd ipv6 config
  EXTRA_DEPENDS:=oonf-init-scripts, oonf-olsrd2
endef

define Package/$(PKG_NAME)-batadv
  $(call Package/luci2-ffwizard/template)
  DEPENDS:=luci2-ffwizard
  TITLE:=Batman advanced
  EXTRA_DEPENDS:=kmod-batman-adv, batctl
endef

define Package/$(PKG_NAME)-kadnode
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

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/menu.d
	$(INSTALL_DATA) files/usr/share/rpcd/menu.d/services.ffwizard.json $(1)/usr/share/rpcd/menu.d/

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) files/usr/share/rpcd/acl.d/services.ffwizard.json $(1)/usr/share/rpcd/acl.d/

	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/ffwizard.d
	$(INSTALL_BIN) files/usr/sbin/ffwizard $(1)/usr/sbin/
	$(INSTALL_BIN) files/usr/sbin/ffwizard_autoconf $(1)/usr/sbin/
	$(INSTALL_BIN) files/etc/ffwizard.d/10-system.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/ffwizard.d/20-network.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/ffwizard.d/50-uhttpd.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/ffwizard.d/60-dhcp.sh $(1)/etc/ffwizard.d/

	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_BIN) files/etc/uci-defaults/61_ffwizard $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/init.d/ffwizard $(1)/etc/init.d/
	$(INSTALL_DATA) files/etc/config/ffwizard $(1)/etc/config/
endef

define Package/luci-app-ffwizard/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/ffwizard
	$(INSTALL_DATA) files/www/luci-static/resources/view/ffwizard/* $(1)/www/luci-static/resources/view/ffwizard
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) files/usr/share/luci/menu.d/luci-app-ffwizard.json $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) files/usr/share/rpcd/acl.d/luci-app-ffwizard.json $(1)/usr/share/rpcd/acl.d
endef

define Package/$(PKG_NAME)-fw/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/uci-defaults/60_ffwizard_fw $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/ffwizard.d/40-firewall.sh $(1)/etc/ffwizard.d/
endef

define Package/$(PKG_NAME)-olsrd-ipv4/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/ffwizard.d/30-olsrd.ipv4.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/uci-defaults/30_ffwizard_olsrd.ipv4 $(1)/etc/uci-defaults/
endef

define Package/$(PKG_NAME)-olsrd-ipv6/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/usr/sbin $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/ffwizard.d/30-olsrd.ipv6.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/uci-defaults/30_ffwizard_olsrd.ipv6 $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/usr/sbin/olsrd-dyn-hna6.sh $(1)/usr/sbin/
	$(INSTALL_BIN) files/usr/sbin/olsrd-dyn-addr.sh $(1)/usr/sbin/
endef

define Package/$(PKG_NAME)-olsrv2-ipv6/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/usr/sbin $(1)/etc/odhcp6c.user.d $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/ffwizard.d/31-olsrd2.ipv6.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/uci-defaults/31_ffwizard_olsrd2.ipv6 $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/odhcp6c.user.d/olsrv2_lan.sh $(1)/etc/odhcp6c.user.d/
	$(INSTALL_BIN) files/usr/sbin/olsrv2-dyn-addr.sh $(1)/usr/sbin/
	$(INSTALL_BIN) files/usr/sbin/olsrneighbor2hosts.sh $(1)/usr/sbin/
	$(INSTALL_BIN) files/usr/sbin/olsrnode2hosts.sh $(1)/usr/sbin/
endef

define Package/$(PKG_NAME)-batadv/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d
	$(INSTALL_BIN) files/etc/ffwizard.d/30-batadv.sh $(1)/etc/ffwizard.d/
endef

define Package/$(PKG_NAME)-kadnode/install
	$(INSTALL_DIR) $(1)/etc/ffwizard.d $(1)/etc/uci-defaults/
	$(INSTALL_BIN) files/etc/ffwizard.d/60-kadnode.sh $(1)/etc/ffwizard.d/
	$(INSTALL_BIN) files/etc/uci-defaults/62_ffwizard_kadnode $(1)/etc/uci-defaults/
endef

$(eval $(call BuildPackage,luci2-ffwizard))
$(eval $(call BuildPackage,luci-app-ffwizard))
$(eval $(call BuildPackage,luci2-ffwizard-olsrd-ipv4))
$(eval $(call BuildPackage,luci2-ffwizard-olsrd-ipv6))
$(eval $(call BuildPackage,luci2-ffwizard-olsrv2-ipv6))
$(eval $(call BuildPackage,luci2-ffwizard-batadv))
$(eval $(call BuildPackage,luci2-ffwizard-kadnode))
$(eval $(call BuildPackage,luci2-ffwizard-fw))
