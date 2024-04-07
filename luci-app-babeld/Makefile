# call BuildPackage - OpenWrt buildroot signature
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-babeld
PKG_VERSION:=git-23.999.80636-70fb460
PKG_RELEASE:=2
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for babeld
  EXTRA_DEPENDS:=luci-mod-public
  PKGARCH:=all
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
	killall -HUP rpcd 2>/dev/null
fi
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/babeld
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/babeld.js $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/babeld/* $(1)/www/luci-static/resources/view/babeld
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./root/etc/uci-defaults/40_luci_babeld $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/* $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/* $(1)/usr/share/rpcd/acl.d
endef

$(eval $(call BuildPackage,luci-app-babeld))
