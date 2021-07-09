#!/bin/bash

dn=$1
domain=$2
admin_dn="cn=$3,$dn"
replica_dn="cn=$4,$dn"



ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: cn=config
changetype: modify
replace: olcServerID
olcServerID: 0
EOF


ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {4}to * by self write by dn="$admin_dn" write by dn="$replica_dn" read by anonymous auth by * none
EOF

exit 0