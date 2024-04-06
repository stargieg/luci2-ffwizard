#!/usr/bin/awk
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
# Copyright (C) 2024 Patrick Grimm
#
##############################################################################
#
# Turn DHCP records into meaningful A, and PTR records.
#
# External Parameters
#   "conffile" = Unbound configuration left for a restart
#   "pipefile" = DNS entries for unbound-control standard input
#   "domain" = text domain suffix
#   "bconf"  = boolean, write conf file with pipe records
#
##############################################################################

{
  # We need to pick out DHCP v4
  hst = $2 ; adr = $1 ;
  gsub( /_/, "-", hst ) ;

  if ( hst !~ /^[[:alnum:]]([-[:alnum:]]*[[:alnum:]])?([\.[:alnum:]]([-[:alnum:]]*[[:alnum:]]))*$/ ) {
    # BUG Support . in hostname
    # that is not a valid host name (RFC1123)
    # above replaced common error of "_" in host name with "-"
    hst = "-" ;
  }
  if ( hst ~ /^localhost$/ ) {
    hst = "-" ;
  }
  if ( hst ~ /^localhost.olsr$/ ) {
    hst = "-" ;
  }
  if ( adr !~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ ) {
    hst = "-" ;
  }

  # fqdn = tolower( hst "." domain ) ;
  fqdn = tolower( hst ) ;

  if (hst != "-") {
    # IPV4 ; only for provided hostnames and full /32 assignments
    ptr = adr ; qpr = "" ; split( ptr, ptr, "." ) ;

    if ( bconf == 1 ) {
      x = ( "local-data: \"" fqdn ". 300 IN A " adr "\"" ) ;
      y = ( "local-data-ptr: \"" adr " 300 " fqdn "\"" ) ;
      print ( x "\n" y "\n" ) > conffile ;
    }

    # always create the pipe file
    for( i=1; i<=4; i++ ) { qpr = ( ptr[i] "." qpr) ; }
    x = ( fqdn ". 300 IN A " adr ) ;
    y = ( qpr "in-addr.arpa. 300 IN PTR " fqdn ) ;
    print ( x "\n" y ) > pipefile ;
  }
  else {
    # dump non-conforming lease records
  }
}
