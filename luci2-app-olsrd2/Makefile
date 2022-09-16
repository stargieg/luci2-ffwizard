#
# Copyright (C) 2016 Patrick <patrick@lunatiki.de>
#
# Licensed under the Apache License, Version 2.0.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci2-app-olsrd2
PKG_VERSION:=2016-06-15
PKG_MAINTAINER:=Patrick <patrick@lunatiki.de>

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Build/Compile
endef

define Package/luci2-app-olsrd2
  SECTION:=luci2
  CATEGORY:=LuCI2
  TITLE:=LuCI2 support for olsrd2 status
  MAINTAINER:=patrick@lunatiki.de
  DEPENDS:=+luci2-ui-base +oonf-olsrd2
  PKGARCH:=all
endef

define Package/luci2-app-olsrd2/description
 Provides the LuCI2 web interface with olsrd2 status informations.
endef

define Package/luci2-app-olsrd2/postinst
#!/bin/sh
if [ -z $${IPKG_INSTROOT} ] ; then
	/etc/init.d/rpcd restart
fi
endef

define Package/luci2-app-olsrd2/install
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./rpcd/status.olsrd2 $(1)/usr/libexec/rpcd/status.olsrd2

	$(INSTALL_DIR) $(1)/usr/share/rpcd
	$(CP) ./share/* $(1)/usr/share/rpcd/

	$(INSTALL_DIR) $(1)/www/luci-ng
	$(CP) ./www/* $(1)/www/luci-ng/
endef

$(eval $(call BuildPackage,luci2-app-olsrd2))
