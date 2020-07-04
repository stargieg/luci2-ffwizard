# call BuildPackage - OpenWrt buildroot signature
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-olsr2
PKG_VERSION:=0.1.1
PKG_RELEASE:=1
PKG_BUILD_DEPENDS += LUCI_APP_OLSR2_SRCDIET:luasrcdiet/host
PKG_CONFIG_DEPENDS += CONFIG_LUCI_APP_OLSR2_SRCDIET
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-olsr2
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=OLSR2 configuration and status module
  EXTRA_DEPENDS:=+oonf-olsrd2, luci-mod-admin-full
endef

define Package/luci-app-bacnet/config
  config LUCI_APP_BACNET_SRCDIET
    bool "olsr2 Minify Lua sources"
    default n
endef

define SrcDiet
  $(FIND) $(1) -type f -name '*.lua' | while read src; do \
    if LUA_PATH="$(STAGING_DIR_HOSTPKG)/lib/lua/5.1/?.lua" luasrcdiet --noopt-binequiv -o "$$$$src.o" "$$$$src"; \
    then mv "$$$$src.o" "$$$$src"; fi; \
  done
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./luasrc $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$(if $(CONFIG_LUCI_APP_BACNET_SRCDIET),$(call SrcDiet,$(PKG_BUILD_DIR)/luasrc/),true);
endef

define Package/luci-app-bacnet/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || {
	rm -f /tmp/luci-indexcache
	exit 0
}
endef

define Package/luci-app-olsr2/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luasrc/controller/* $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luasrc/model/cbi/* $(1)/usr/lib/lua/luci/model/cbi/bacnet
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/status-olsr2
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/luasrc/view/status-olsr2/* $(1)/usr/lib/lua/luci/view/status-olsr2
	$(INSTALL_DIR) $(1)/www/
	$(INSTALL_DATA) ./htdocs/* $(1)/www
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./root/etc/config/* $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_DATA) ./root/etc/uci-defaults/* $(1)/etc/uci-defaults
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./root/usr/bin/* $(1)/usr/bin
endef

$(eval $(call BuildPackage,luci-app-olsr2))
