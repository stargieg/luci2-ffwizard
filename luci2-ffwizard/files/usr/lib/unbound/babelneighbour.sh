#!/bin/sh
##############################################################################
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# Copyright (C) 2016 Eric Luehrsen
#
##############################################################################
#
# This script facilitates alternate to make a forward "zone" entries.
#
##############################################################################

# while useful (sh)ellcheck is pedantic and noisy
# shellcheck disable=1091,2002,2004,2034,2039,2086,2094,2140,2154,2155

UB_ODHCPD_BLANK=

##############################################################################

zonedata() {
  . /lib/functions.sh
  . /usr/lib/unbound/defaults.sh

  local origin="/tmp/hosts/babelneighbor"
  UB_CONF=$UB_VARDIR/babelneighbor.conf

  if [ -f "$UB_TOTAL_CONF" ] && [ -f "$origin" ] ; then
    local longconf dateconf dateoldf
    local dns_add=$UB_VARDIR/babelneighbor_dns.add
    local dns_del=$UB_VARDIR/babelneighbor_dns.del
    local dns_new=$UB_VARDIR/babelneighbor_dns.new
    local dns_old=$UB_VARDIR/babelneighbor_dns.old
    local origin_new=$UB_VARDIR/babelneighbor.new


    if [ ! -f $UB_CONF ] || [ ! -f $dns_old ] ; then
      # no old files laying around
      touch $dns_old
      sort $origin > $origin_new
      longconf=freshstart

    else
      # incremental at high load or full refresh about each 5 minutes
      dateconf=$(( $( date +%s ) - $( date -r $UB_CONF +%s ) ))
      dateoldf=$(( $( date +%s ) - $( date -r $dns_old +%s ) ))


      if [ $dateconf -gt 60 ] ; then
        touch $dns_old
        sort $origin > $origin_new
        longconf=longtime

      elif [ $dateoldf -gt 1 ] ; then
        touch $dns_old
        sort $origin > $origin_new
        longconf=increment

      else
        # odhcpd is rapidly updating leases a race condition could occur
        longconf=skip
      fi
    fi


    case $longconf in
    freshstart)
      awk -v conffile=$UB_CONF -v pipefile=$dns_new -v bconf=1 \
          -f /usr/lib/unbound/babel.awk $origin_new

      cp $dns_new $dns_add
      cp $dns_new $dns_old
      cat $dns_add | $UB_CONTROL_CFG local_datas
      rm -f $dns_new $dns_del $dns_add $origin_new
      ;;

    longtime)
      awk -v conffile=$UB_CONF -v pipefile=$dns_new \
          -v bconf=1 \
          -f /usr/lib/unbound/babel.awk $origin_new

      #BUG remove to much
      awk '{ print $1 }' $dns_old | sort | uniq > $dns_del
      #BUG remove nothing
      #cat $dns_old | sort | uniq > $dns_del
      cp $dns_new $dns_add
      cp $dns_new $dns_old
      cat $dns_del | $UB_CONTROL_CFG local_datas_remove
      cat $dns_add | $UB_CONTROL_CFG local_datas
      rm -f $dns_new $dns_del $dns_add $origin_new
      ;;

    increment)
      # incremental add and prepare the old list for delete later
      # unbound-control can be slow so high DHCP rates cannot run a full list
      awk -v conffile=$UB_CONF -v pipefile=$dns_new \
          -v bconf=0 \
          -f /usr/lib/unbound/babel.awk $origin_new

      sort $dns_new $dns_old $dns_old | uniq -u > $dns_add
      sort $dns_new $dns_old | uniq > $dns_old
      cat $dns_add | $UB_CONTROL_CFG local_datas
      rm -f $dns_new $dns_del $dns_add $origin_new
      ;;

    *)
      echo "do nothing" >/dev/null
      ;;
    esac
  fi
}

##############################################################################

UB_LOCK=/tmp/unbound_babelneighbor.lock

if [ ! -f $UB_LOCK ] ; then
  # imperfect but it should avoid collisions
  touch $UB_LOCK
  zonedata
  rm -f $UB_LOCK

else
  UB_LOCK_AGE=$(( $( date +%s ) - $( date -r $UB_LOCK +%s ) ))

  if [ $UB_LOCK_AGE -gt 100 ] ; then
    # unlock because something likely broke but do not write this time through
    rm -f $UB_LOCK
  fi
fi

##############################################################################

