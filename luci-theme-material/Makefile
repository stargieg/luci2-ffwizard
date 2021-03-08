# call BuildPackage - OpenWrt buildroot signature
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-theme-material
PKG_VERSION:=git-99.000.0-0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/luci-theme-material
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=4. Themes
  TITLE:=Material Theme
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || {
	(. /etc/uci-defaults/30_luci-theme-material) && rm -f /etc/uci-defaults/30_luci-theme-material
	rm -f /tmp/luci-indexcache
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null
	exit 0
}
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/themes/material
	$(INSTALL_DATA) ./luasrc/view/themes/material/* $(1)/usr/lib/lua/luci/view/themes/material
	$(INSTALL_DIR) $(1)/www/
	cp -pR ./htdocs/* $(1)/www/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults
endef

$(eval $(call BuildPackage,luci-theme-material))
