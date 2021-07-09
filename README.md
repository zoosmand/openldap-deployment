# OpenLDAP deployment hints

## 0. Read this

        https://wiki.debian.org/LDAP/OpenLDAPSetup

## 1. Install

- step 1

        apt install slapd ldap-utils schema2ldif

- step 2

        ldapsearch -x -LLL -s base -b "" namingContexts
        dn:
        namingContexts: dc=fan-240,dc=mira,dc=asart,dc=local

## 2. Delete rootd DN and Naming Context

- step 1

        ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config

- step 2

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        replace: olcRootDN
        olcRootDN: cn=admin,dc=impresso,dc=org
        -
        replace: olcSuffix
        olcSuffix: dc=impresso,dc=org
        EOF

## 3. Check schema, add a schema file if necessary

- step 1

        ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config dn

- step 2

        schema2ldif /usr/share/doc/<package>/<xyz>.schema > /tmp/<xyz>.ldif

- step 3

        ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/<xyz>.ldif

- exapmles

        schema2ldif /usr/share/doc/samba/examples/LDAP/samba.schema > /tmp/samba.ldif
        ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/samba.ldif
        schema2ldif /usr/share/doc/freeradius/schemas/ldap/openldap/freeradius.schema > /tmp/radius.ldif
        ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/radius.ldif

## 4. Change permissions

- step 1

        ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess

- step 2

        ldapsearch -x -b "dc=impresso,dc=org"

- step 3

        ldapsearch -x -D "cn=admin,dc=impresso,dc=org" -W -b "dc=impresso,dc=org"

- step 4

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcAccess
        olcAccess: {1}to attrs=loginShell,gecos by dn="cn=admin,dc=impresso,dc=org" write by self write by * read
        EOF

## 5. Create the root

- step 1

        ldapadd -x -W -D 'cn=admin,dc=impresso,dc=org' <<EOF
        dn: dc=impresso,dc=org
        objectClass: dcObject
        objectclass: organization
        o: impresso.org
        dc: Impresso
        description: Impresso LDAP Root

        dn: cn=admin,dc=impresso,dc=org
        objectClass: simpleSecurityObject
        objectClass: organizationalRole
        cn: admin
        userPassword: xxx
        description: LDAP administrator
        EOF

- step 2 opt.

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        delete: olcRootPW
        EOF

- step 3

        ldapsearch -x -b "dc=impresso,dc=org"
        ldapsearch -x -D "cn=admin,dc=impresso,dc=org" -W -b "cn=admin,dc=impresso,dc=org"

## 6. Change password

- step 1

        slappasswd

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        replace: olcRootPW
        olcRootPW: xxxxxx
        EOF

- step 2

        ldappasswd -x -D cn=admin,dc=impresso,dc=org -W -S

- step 3

        ldapwhoami -x -D cn=admin,dc=impresso,dc=org -W

## 7. Logging

- step 1

        ldapmodify -Q -H ldapi:/// -Y EXTERNAL <<EOF
        dn: cn=config
        changetype: modify
        replace: olcLogLevel
        olcLogLevel: stats
        EOF

## 8. DB Max size

- step 1

        ldapmodify -H ldapi:/// -Y EXTERNAL << EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        replace: olcDbMaxSize
        olcDbMaxSize: 10737418240
        EOF

## 9. Indexes

- step 1

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        replace: olcDbIndex
        olcDbIndex: cn pres,sub,eq
        -
        add: olcDbIndex
        olcDbIndex: sn pres,sub,eq
        -
        add: olcDbIndex
        olcDbIndex: uid pres,sub,eq
        -
        add: olcDbIndex
        olcDbIndex: displayName pres,sub,eq
        -
        add: olcDbIndex
        olcDbIndex: default sub
        -
        add: olcDbIndex
        olcDbIndex: uidNumber eq
        -
        add: olcDbIndex
        olcDbIndex: gidNumber eq
        -
        add: olcDbIndex
        olcDbIndex: mail,givenName eq,subinitial
        -
        add: olcDbIndex
        olcDbIndex: dc eq
        EOF

## 10. TLS

- step 1

        read EASY-RSA.md

- step 2

        expanse key file permissions for openldap user

- step 3

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
        dn: cn=config
        changetype: modify
        replace: olcTLSCertificateKeyFile
        olcTLSCertificateKeyFile: /etc/ldap/cert/ldap.impresso.org.key
        -
        replace: olcTLSCertificateFile
        olcTLSCertificateFile: /etc/ldap/cert/ldap.impresso.org.crt
        -
        replace: olcTLSCACertificateFile
        olcTLSCACertificateFile: /etc/ldap/cert/ca.impresso.org.crt
        EOF

- step 4

        cat > /etc/default/slapd <<EOF
        SLAPD_CONF=
        SLAPD_USER="openldap"
        SLAPD_GROUP="openldap"
        SLAPD_PIDFILE=
        SLAPD_SERVICES="ldap://127.0.0.1/ ldapi:/// ldaps:///"
        #SLAPD_NO_START=1
        SLAPD_SENTINEL_FILE=/etc/ldap/noslapd
        #export KRB5_KTNAME=/etc/krb5.keytab
        SLAPD_OPTIONS=""
        EOF

### Other

    ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config -s one olcAccess
    ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config dn
    ldapsearch -Y EXTERNAL -H ldapi:/// -LLLQ -b "cn=config" -s base subschemaSubentry
    ldapsearch -x -LLL -b cn=Subschema -s base '(objectClass=subschema)' +
    ldapsearch -x -LLL -b cn=Subschema -s base -o ldif-wrap=no '(objectClass=subschema)' + | grep "^objectClasses:" | grep "NAME 'olcGlobal'"

    echo '{SSHA}'$(echo $(echo -n passwordsalt | shasum -a 1 | awk '{print $1}')salt | base64)
    ldapdelete -x -D "cn=admin,dc=fan-240,dc=mira,dc=asart,dc=local" -W -H ldapi:/// cn=admin,dc=fan-240,dc=mira,dc=asart,dc=local

    ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b dc=fan-240,dc=mira,dc=asart,dc=local
