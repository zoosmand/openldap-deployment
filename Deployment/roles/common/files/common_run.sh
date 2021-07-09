#!/bin/bash

dn=$1
domain=$2
admin_username=$3
replica_username=$4
root_password=$5
admin_password=$6
replica_password=$7
org_short_name=$8

admin_dn="cn=$admin_username,$dn"
replica_dn="cn=$replica_username,$dn"

# change root DN
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: $admin_dn
EOF

# change LDAP suffix
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: $dn
EOF

# add DIT and two records stated to admin and replica users
ldapadd -x -w xxxxxx -D "$admin_dn" <<EOF
dn: $dn
objectClass: dcObject
objectclass: organization
o: $domain
dc: $org_short_name
description: $org_short_name LDAP Root

dn: $admin_dn
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: $admin_username
userPassword: $admin_password
description: LDAP administrator

dn: $replica_dn
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: $replica_username
userPassword: $replica_password
description: Replication Administrator
EOF

# change root password
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $root_password
EOF

# unlimit user for replication purposes
ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcLimits
olcLimits: {0}dn.exact="$replica_dn" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited
EOF

# add some access rules
ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {2}to dn="$admin_dn" by self write by * none
-
add: olcAccess
olcAccess: {3}to dn="$replica_dn" by dn="$admin_dn" write by * none
EOF


exit 0