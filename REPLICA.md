
# OpenLDAP delta replication deployment hints

ldapsearch -LLLQ -Y EXTERNAL -H ldapi:/// -b cn=config

- Add replica user

        ldapadd -x -D cn=admin,dc=impresso,dc=org -W <<EOF
        dn: cn=replica,dc=impresso,dc=org
        objectClass: simpleSecurityObject
        objectClass: organizationalRole
        cn: replica
        description: Replication Administrator
        userPassword: xxx
        EOF

- Add indexes to the frontend db

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcDbIndex
        olcDbIndex: entryCSN eq
        -
        add: olcDbIndex
        olcDbIndex: entryUUID eq
        EOF

- Load the syncprov and accesslog modules

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: cn=module{0},cn=config
        changetype: modify
        add: olcModuleLoad
        olcModuleLoad: syncprov
        -
        add: olcModuleLoad
        olcModuleLoad: accesslog
        EOF

- Add hdb module

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: cn=module{0},cn=config
        changetype: modify
        add: olcModuleLoad
        olcModuleLoad: back_hdb
        EOF

- Accesslog database definitions

        mkdir /var/lib/ldap/accesslog
        chown openldap:openldap /var/lib/ldap/accesslog

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={2}hdb,cn=config
        changetype: add
        objectClass: olcDatabaseConfig
        objectClass: olcHdbConfig
        olcDatabase: {2}hdb
        olcDbDirectory: /var/lib/ldap/accesslog
        olcSuffix: cn=accesslog
        olcRootDN: cn=replica,dc=impresso,dc=org
        olcDbIndex: default eq
        olcDbIndex: entryCSN,objectClass,reqEnd,reqResult,reqStart
        EOF

- Accesslog db syncprov

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcOverlay=syncprov,olcDatabase={2}hdb,cn=config
        changetype: add
        objectClass: olcOverlayConfig
        objectClass: olcSyncProvConfig
        olcOverlay: syncprov
        olcSpNoPresent: TRUE
        olcSpReloadHint: TRUE
        EOF

- syncrepl Provider for primary db

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
        changetype: add
        objectClass: olcOverlayConfig
        objectClass: olcSyncProvConfig
        olcOverlay: syncprov
        olcSpNoPresent: TRUE
        EOF

- accesslog overlay definitions for primary db, scan the accesslog DB every day, and purge entries older than 7 days

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcOverlay=accesslog,olcDatabase={1}mdb,cn=config
        changetype: add
        objectClass: olcOverlayConfig
        objectClass: olcAccessLogConfig
        olcOverlay: accesslog
        olcAccessLogDB: cn=accesslog
        olcAccessLogOps: writes
        olcAccessLogSuccess: TRUE
        olcAccessLogPurge: 07+00:00 01+00:00
        EOF

- add replication node

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        delete: olcSyncRepl
        EOF

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcSyncRepl
        olcSyncRepl: rid=0 provider=ldaps://ldap.impresso.org bindmethod=simple binddn="cn=replica,dc=impresso,dc=org" credentials=zzzzzz searchbase="dc=impresso,dc=org" logbase="cn=accesslog" logfilter="(&(objectClass=auditWriteObject)(reqResult=0))" schemachecking=on type=refreshAndPersist retry="5 10 300 +" syncdata=accesslog tls_cert=/etc/ldap/cert/ldap2.impresso.org.crt tls_key=/etc/ldap/cert/ldap2.impresso.org.key tls_cacert=/etc/ssl/cert/ca.impresso.org.crt scope=sub attrs="*,+"
        -
        add: olcUpdateRef
        olcUpdateRef: ldaps://ldap.impresso.org
        -
        add: olcMirrorMode
        olcMirrorMode: TRUE
        EOF

- give rigths for replication

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcAccess
        olcAccess: {3} to * by self write by anonymous auth by dn="cn=admin,dc=impresso,dc=org" write by dn="cn=replica,dc=impresso,dc=org" write by * read
        EOF

- remove default rights

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        delete: olcAccess
        olcAccess: {4}
        EOF

- setup access rigths

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcAccess
        olcAccess: {0} to attrs=userPassword by self write by anonymous auth by * none
        -
        add: olcAccess
        olcAccess: {1} to attrs=shadowLastChange by self write by * read
        -
        add: olcAccess
        olcAccess: {2} to dn="cn=admin,dc=impresso,dc=org" by self write by * none
        -
        add: olcAccess
        olcAccess: {3} to dn="cn=replica,dc=impresso,dc=org" by dn="cn=admin,dc=impresso,dc=org" write by * none
        -
        add: olcAccess
        olcAccess: {4} to dn.subtree="ou=dns,ou=services,dc=impresso,dc=org" by * read
        -
        add: olcAccess
        olcAccess: {5} to * by dn="cn=admin,dc=impresso,dc=org" write by dn="cn=replica,dc=impresso,dc=org" write by anonymous auth by * none
        EOF

# OpenLDAP master-master (mirror) or master-slave(s) replication deployment hints

- Add replica user

        ldapadd -x -D cn=admin,dc=impresso,dc=org -W <<EOF
        dn: cn=replica,dc=impresso,dc=org
        objectClass: simpleSecurityObject
        objectClass: organizationalRole
        cn: replica
        description: Replication Administrator
        userPassword: xxx
        EOF

- Add indexes to the frontend db

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcDbIndex
        olcDbIndex: objectclass,entryCSN,entryUUID eq
        EOF

- Load the syncprov modules

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: cn=module{0},cn=config
        changetype: modify
        add: olcModuleLoad
        olcModuleLoad: syncprov
        EOF

- add replication node

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcSyncRepl
        olcSyncRepl: rid=1 provider=ldaps://master.ldap.impresso.org bindmethod=simple binddn="cn=replica,dc=impresso,dc=org" credentials=zzzzzz searchbase="dc=impresso,dc=org" schemachecking=on type=refreshAndPersist retry="5 10 300 +" tls_cert=/etc/ldap/cert/server.crt tls_key=/etc/ldap/cert/server.key tls_cacert=/etc/ssl/cert/ca.crt attrs="*,+"
        EOF

        ### if mirror type used ###
        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcMirrorMode
        olcMirrorMode: TRUE
        EOF

- unlimit replica user

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcLimits
        olcLimits: dn.exact="cn=replica,dc=impresso,dc=org" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited
        EOF

# Other hints

- delete limits

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        delete: olcLimits
        olcLimits: {0}
        EOF

- add limits

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcLimits
        olcLimits: dn.exact="cn=replica,dc=impresso,dc=org" time.soft=unlimited time.hard=unlimited size.soft=unlimited size.hard=unlimited
        EOF

- change root DN

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        replace: olcRootDN
        olcRootDN: cn=admin,dc=localhost
        -
        replace: olcSuffix
        olcSuffix: dc=localhost
        EOF

- change root password

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        replace: olcRootPW
        olcRootPW: xxxxxx
        EOF

- delete access

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        delete: olcAccess
        olcAccess: {2}
        EOF

- add access

        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcAccess
        olcAccess: {4}to * by self write by dn="cn=admin,dc=impesso,dc=org" write by dn="cn=replica,dc=impresso,dc=org" write by anonymous auth by * none
        EOF


        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcAccess
        olcAccess: {3} to dn.base="" by anonymous auth by * none
        EOF


        ldapmodify -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcAccess
        olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
        -
        add: olcAccess
        olcAccess: {1}to attrs=shadowLastChange by self write by * read
        -
        add: olcAccess
        olcAccess: {2}to * by * read
        EOF

- change indexes

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        delete: olcDbIndex
        olcDbIndex: entryCSN eq
        -
        delete: olcDbIndex
        olcDbIndex: entryUUID eq
        -
        add: olcDbIndex
        olcDbIndex: objectclass,entryCSN,entryUUID eq
        EOF

- add checkpoint

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcDbCheckpoint
        olcCheckPoint: 1024 5
        EOF

- delete replication source

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        delete: olcSyncRepl
        EOF
        -
        delete: olcMirrorMode
        EOF

- add replication source

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcSyncRepl
        olcSyncRepl: rid=1 provider=ldaps://master.ldap.impresso.org bindmethod=simple binddn="cn=replica,dc=impresso,dc=org" credentials=zzzzzz searchbase="dc=impresso,dc=org" schemachecking=on type=refreshAndPersist retry="5 10 300 +" tls_cert=/etc/ldap/cert/server.crt tls_key=/etc/ldap/cert/server.key tls_cacert=/etc/ssl/cert/ca.crt attrs="*,+"
        EOF

- add server ID

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: cn=config
        changetype: modify
        add: olcServerID
        olcServerID: 1
        EOF

- seeking

        ldapsearch -H ldaps://master.ldap.impresso.org -LLL -D "cn=replica,dc=impresso,dc=org" -W -b "dc=impresso,dc=org"
        ldapsearch -H ldaps://master.ldap.impresso.org -LLL -D "cn=replica,dc=impresso,dc=org" -W -b "olcServerId"

- add data

        ldapadd -x -w xxxxxx -D "cn=admin,dc=localhost" <<EOF
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
        userPassword: yyyyyy
        description: LDAP administrator

        dn: cn=replica,dc=impresso,dc=org
        objectClass: simpleSecurityObject
        objectClass: organizationalRole
        cn: replica
        userPassword: zzzzzz
        description: Replication Administrator
        EOF
