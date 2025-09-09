#
# Copyright (C) 2012-2013 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=collectd-mod-ip-neigh
PKG_VERSION:=2025.09.09
PKG_RELEASE:=4

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)/default
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=collectd-mod-ip-neigh
  PKGARCH:=all
  EXTRA_DEPENDS:=collectd-mod-exec
endef

define Package/$(PKG_NAME)/description
  Collectd mod that use mod-exec
  Usage with luci_statistics
  Add exec_input config
  uci set luci_statistics.collectd_exec.enable='1'
  uci add luci_statistics collectd_exec_input
  uci set luci_statistics.@collectd_exec_input[-1].cmdline='/usr/libexec/collectd-mod-ip-neigh.sh br-lan'
  uci set luci_statistics.@collectd_exec_input[-1].cmduser='nobody'
  uci set luci_statistics.@collectd_exec_input[-1].cmdgroup='nogroup'
  Disable collectd_dhcpleases
  uci del luci_statistics.collectd_dhcpleases.enable
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/libexec
	$(INSTALL_BIN) files/collectd-mod-ip-neigh.sh $(1)/usr/libexec
endef


$(eval $(call BuildPackage,collectd-mod-ip-neigh))
