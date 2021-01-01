#
# Copyright (C) 2008-2014 The LuCI Team <luci@lists.subsignal.org>
#
# This is free software, licensed under the Apache License, Version 2.0 .
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-mod-freifunk
PKG_VERSION:=git-20.365.0-0
PKG_RELEASE:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/luci-mod-freifunk
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=2. Modules
  TITLE:=LuCI Freifunk module
  EXTRA_DEPENDS:=freifunk-common, luci-mod-public
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
	rm -f /tmp/luci-indexcache
	rm -rf /tmp/luci-modulecache/
	killall -HUP rpcd 2>/dev/null
	exit 0
}
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/freifunk
	$(INSTALL_DATA) ./luasrc/controller/freifunk/* $(1)/usr/lib/lua/luci/controller/freifunk
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/freifunk
	$(INSTALL_DATA) ./luasrc/model/cbi/freifunk/* $(1)/usr/lib/lua/luci/model/cbi/freifunk
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/freifunk
	$(INSTALL_DATA) ./luasrc/view/freifunk/* $(1)/usr/lib/lua/luci/view/freifunk
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/* $(1)/usr/share/rpcd/acl.d
endef

$(eval $(call BuildPackage,luci-mod-freifunk))
