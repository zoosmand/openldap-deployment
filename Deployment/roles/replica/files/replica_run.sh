#!/bin/bash

dn=$1
domain=$2
node=$3
master_node=$4
replica_dn="cn=$5,$dn"
replica_password=$6
admin_dn="cn=$7,$dn"

ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {4}to * by self write by dn="$admin_dn" write by dn="$replica_dn" write by anonymous auth by * none
EOF

ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcServerID
olcServerID: $node
EOF

ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=00$node provider=ldaps://$master_node.ldap.$domain bindmethod=simple binddn="$replica_dn" credentials=$replica_password searchbase="$dn" schemachecking=on type=refreshAndPersist retry="5 10 300 +" tls_cert=/etc/ldap/cert/server.crt tls_key=/etc/ldap/cert/server.key tls_cacert=/etc/ssl/cert/ca.crt attrs="*,+"
-
add: olcMirrorMode
olcMirrorMode: TRUE
EOF


exit 0