# call BuildPackage - OpenWrt buildroot signature
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-olsrd2
PKG_VERSION:=0.2.6
PKG_RELEASE:=25
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=OLSR2 configuration and status module
  MAINTAINER:=Patrick Grimm <patrick@lunatiki.de>
  EXTRA_DEPENDS:=oonf-olsrd2, luci-mod-admin-full
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/luci_olsrd2
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	rm -f /tmp/luci-indexcache
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null
fi
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/olsrd2
	$(INSTALL_DATA) ./htdocs/cgi-bin-olsrd2-neigh.html $(1)/www
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/olsrd2/* $(1)/www/luci-static/resources/view/olsrd2
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/* $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./root/usr/libexec/rpcd/status.olsrd2 $(1)/usr/libexec/rpcd/status.olsrd2
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/* $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/* $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DIR) $(1)/lib/functions
	$(INSTALL_DATA) ./root/lib/functions/* $(1)/lib/functions
endef

$(eval $(call BuildPackage,luci-app-olsrd2))
