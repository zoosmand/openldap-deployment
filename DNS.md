# DNS woth OpenLDAP backend deployment hints

- install package

        apt install bind9-dyndb-ldap

- add schema

        zcat /usr/share/doc/bind9-dyndb-ldap/schema.ldif.gz | sed 's/^attributeTypes:/olcAttributeTypes:/;
        s/^objectClasses:/olcObjectClasses:/;
        1,/1.3.6.1.4.1.2428.20.0.0/ {/1.3.6.1.4.1.2428.20.0.0/!s/^/#/};
        1idn: cn=dns,cn=schema,cn=config\nobjectClass: olcSchemaConfig
        ' >> /tmp/dns.ldif

        ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/dns.ldif

- add module

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: cn=module{0},cn=config
        changetype: modify
        add: olcModuleLoad
        olcModuleLoad: syncprov
        EOF

- setup overlay

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// <<EOF
        dn: olcOverlay=syncprov,olcDatabase={1}mdb,cn=config
        changeType: add
        objectClass: olcOverlayConfig
        objectClass: olcSyncProvConfig
        olcOverlay: syncprov
        olcSpCheckpoint: 100 10
        olcSpSessionLog: 100
        EOF

- add index

        ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
        dn: olcDatabase={1}mdb,cn=config
        changetype: modify
        add: olcDbIndex
        olcDbIndex: objectclass,entryCSN,entryUUID eq
        EOF

- add ou=Services

        ldapadd -x -D cn=admin,dc=impresso,dc=org -W <<EOF
        dn: ou=services,dc=impresso,dc=org
        objectClass: organizationalUnit
        objectClass: top
        ou: Services

- add ou=dns

        ldapadd -x -D cn=admin,dc=impresso,dc=org -W <<EOF
        dn: ou=dns,ou=services,dc=impresso,dc=org
        objectClass: organizationalUnit
        objectClass: top
        ou: dns
        EOF

- add zone

        ldapadd -x -D cn=admin,dc=impresso,dc=org -W <<EOF
        # Zone impresso.org
        dn: idnsName=impresso.org,ou=dns,ou=Services,dc=impresso,dc=org
        objectClass: top
        objectClass: idnsZone
        objectClass: idnsRecord
        idnsName: impresso.org
        idnsUpdatePolicy: grant impresso.org krb5-self * A;
        idnsZoneActive: TRUE
        idnsSOAmName: ns.impresso.org
        idnsSOArName: admin.impresso.org
        idnsSOAserial: 2021070401
        idnsSOArefresh: 10800
        idnsSOAretry: 900
        idnsSOAexpire: 604800
        idnsSOAminimum: 86400
        NSRecord: ns.asart.org.
        NSRecord: ns2.asart.org.
        NSRecord: ns3.asart.org.
        ARecord: 46.48.31.213

        # DNS records for zone impresso.org
        dn: idnsName=ldap,idnsName=impresso.org,ou=dns,ou=services,dc=impresso,dc=org
        objectClass: idnsRecord
        objectClass: top
        idnsName: ldap
        CNAMERecord: impresso.org.

        dn: idnsName=ntp,idnsName=impresso.org,ou=dns,ou=services,dc=impresso,dc=org
        objectClass: idnsRecord
        objectClass: top
        idnsName: ntp
        CNAMERecord: impresso.org.

        dn: idnsName=_ldap._tcp,idnsName=impresso.org,ou=dns,ou=services,dc=impresso,dc=org
        objectClass: idnsRecord
        objectClass: top
        idnsName: _ldap._tcp
        SRVRecord: 0 100 636 ldap

        dn: idnsName=_ntp._udp,idnsName=impresso.org,ou=dns,ou=services,dc=impresso,dc=org
        objectClass: idnsRecord
        objectClass: top
        idnsName: _ntp._udp
        SRVRecord: 0 100 123 ntp
        EOF

- modyfy /etc/bind/named.conf.local

        dyndb "db_name" "/usr/lib/bind/ldap.so" {
        //uri "ldapi:///";
        uri "ldap://localhost";
        base "ou=dns,ou=Services,dc=impresso,dc=org";
        auth_method "none";
        //auth_method "simple";
        //bind_dn "cn=admin,dc=impresso,dc=org";
        //password "password";
        //server_id "db_ns";
        };
