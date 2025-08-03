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
# Turn olsr records into meaningful AAAA, and PTR records.
#
# External Parameters
#   "conffile" = Unbound configuration left for a restart
#   "pipefile" = DNS entries for unbound-control standard input
#   "bconf"  = boolean, write conf file with pipe records
#
##############################################################################

{
  # We need to pick out DHCP v4
  adr = $1 ; hst = $2 ; olsrhst = $3 ;
  gsub( /_/, "-", hst ) ;
  gsub( /_/, "-", olsrhst ) ;

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
  if ( olsrhst !~ /^[[:alnum:]]([-[:alnum:]]*[[:alnum:]])?([\.[:alnum:]]([-[:alnum:]]*[[:alnum:]]))*$/ ) {
    # BUG Support . in hostname
    # that is not a valid host name (RFC1123)
    # above replaced common error of "_" in host name with "-"
    olsrhst = "-" ;
  }
  if ( olsrhst ~ /^localhost$/ ) {
    olsrhst = "-" ;
  }
  if ( olsrhst ~ /^localhost.olsr$/ ) {
    olsrhst = "-" ;
  }

  # fqdn = tolower( hst "." domain ) ;
  fqdn = tolower( hst ) ;

  if (hst != "-") {
    # TODO fqdn 300 IN CAA 0 issue letsencrypt.org
    if ( bconf == 1 ) {
      # w = ( "local-data: \"" fqdn ". 300 IN CAA 0 issue letsencrypt.org\"" ) ;
      x = ( "local-data: \"" fqdn ". 300 IN AAAA " adr "\"" ) ;
      y = ( "local-data-ptr: \"" adr " 300 " fqdn "\"" ) ;
      #print ( w "\n" x "\n" y "\n" ) > conffile ;
      print ( x "\n" y "\n" ) > conffile ;
    }

    # only for provided hostnames and full /128 assignments
    qpr = ipv6_ptr( adr ) ;
    # w = ( fqdn ". 300 IN CAA 0 issue letsencrypt.org" ) ;
    x = ( fqdn ". 300 IN AAAA " adr ) ;
    y = ( qpr ". 300 IN PTR " fqdn ) ;
    # print ( w "\n" x "\n" y ) > pipefile ;
    print ( x "\n" y ) > pipefile ;
  }
  else if (olsrhst != "-") {
    fqdn = tolower( olsrhst ) ;
    if ( bconf == 1 ) {
      x = ( "local-data: \"" fqdn ". 300 IN AAAA " adr "\"" ) ;
      print ( x "\n" ) > conffile ;
    }

    x = ( fqdn ". 300 IN AAAA " adr ) ;
    print ( x ) > pipefile ;
  }
  else {
    # dump non-conforming lease records
  }
}

##############################################################################

function ipv6_ptr( ipv6,    arpa, ary, end, i, j, new6, sz, start ) {
  # IPV6 colon flexibility is a challenge when creating [ptr].ip6.arpa.
  sz = split( ipv6, ary, ":" ) ; end = 9 - sz ;


  for( i=1; i<=sz; i++ ) {
    if( length(ary[i]) == 0 ) {
      for( j=1; j<=end; j++ ) { ary[i] = ( ary[i] "0000" ) ; }
    }

    else {
      ary[i] = substr( ( "0000" ary[i] ), length( ary[i] )+5-4 ) ;
    }
  }


  new6 = ary[1] ;
  for( i = 2; i <= sz; i++ ) { new6 = ( new6 ary[i] ) ; }
  start = length( new6 ) ;
  for( i=start; i>0; i-- ) { arpa = ( arpa substr( new6, i, 1 ) ) ; } ;
  gsub( /./, "&\.", arpa ) ; arpa = ( arpa "ip6.arpa" ) ;

  return arpa ;
}
