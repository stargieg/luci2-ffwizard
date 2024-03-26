#
# Copyright (C) 2012-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-falter-owm
PKG_VERSION:=2023.02.25
PKG_RELEASE:=2

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/default
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  URL:=https://github.com/Freifunk-Spalter/packages
  PKGARCH:=all
endef

define Package/$(PKG_NAME)-cmd
  $(call Package/luci-app-falter-owm/default)
  TITLE:=luci-app-falter-owm-cmd - Commandline update tool
endef
define Package/$(PKG_NAME)-cmd/description
  Luci JSON Export for Open Wireless Map
endef

define Package/$(PKG_NAME)-gui
  $(call Package/luci-app-falter-owm/default)
  EXTRA_DEPENDS:=luci-app-falter-owm-cmd, luci-base
  TITLE:=luci-app-falter-owm-gui - GUI Open Wireless Map
endef

define Package/$(PKG_NAME)/conffiles
/etc/config/antennas
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./luasrc $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)-cmd/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	( . /etc/uci-defaults/owm ) && rm -f /etc/uci-defaults/owm
	rm -f /tmp/luci-indexcache
fi
endef

define Package/$(PKG_NAME)-cmd/install
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(CP) files/owm.sh $(1)/usr/sbin/owm.sh
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(CP) files/owm-defaults $(1)/etc/uci-defaults/owm
	$(INSTALL_DIR) $(1)/etc/init.d $(1)/etc/config $(1)/etc/uci-defaults
	$(INSTALL_DATA) files/antennas.config $(1)/etc/config/antennas
endef

define Package/$(PKG_NAME)-gui/install
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/* $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/* $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/www/
	cp -pR ./htdocs/* $(1)/www/
endef


$(eval $(call BuildPackage,luci-app-falter-owm-cmd))
$(eval $(call BuildPackage,luci-app-falter-owm-gui))

