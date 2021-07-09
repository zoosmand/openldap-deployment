# EasyRSA deployment hints

- install easy-rsa

        apt install easy-rsa

- edit files

        cat > vars <<EOF
        if [ -z "$EASYRSA_CALLER" ]; then
                echo "You appear to be sourcing an Easy-RSA 'vars' file." >&2
                echo "This is no longer necessary and is disallowed. See the section called" >&2
                echo "'How to use this file' near the top comments for more details." >&2
                return 1
        fi
        set_var EASYRSA                 "${0%/*}"
        set_var EASYRSA_OPENSSL         "openssl"
        set_var EASYRSA_PKI             "$PWD/pki"
        set_var EASYRSA_DN              "org"
        set_var EASYRSA_REQ_COUNTRY     "RU"
        set_var EASYRSA_REQ_PROVINCE    "Ural"
        set_var EASYRSA_REQ_CITY        "Yekaterinburg"
        set_var EASYRSA_REQ_ORG         "Impresso Ltd."
        set_var EASYRSA_REQ_EMAIL       "admin@impresso.org"
        set_var EASYRSA_REQ_OU          "IT Department"
        set_var EASYRSA_KEY_SIZE        4096
        set_var EASYRSA_ALGO            rsa
        set_var EASYRSA_CA_EXPIRE       3650
        set_var EASYRSA_CERT_EXPIRE     1080
        set_var EASYRSA_CERT_RENEW      30
        set_var EASYRSA_CRL_DAYS        180
        set_var EASYRSA_NS_SUPPORT      "yes"
        set_var EASYRSA_NS_COMMENT      "Impresso CA Generated Certificate"
        set_var EASYRSA_EXT_DIR         "$EASYRSA/x509-types"
        set_var EASYRSA_SSL_CONF        "$EASYRSA/openssl-easyrsa.cnf"
        set_var EASYRSA_DIGEST          "sha256"
        EOF

        cat > x509-types/server <<EOF
        basicConstraints = CA:FALSE
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid,issuer:always
        extendedKeyUsage = serverAuth
        keyUsage = Digital Signature, Non Repudiation, Key Encipherment, Data Encipherment
        EOF

- create certificates

        ./easyrsa init-pki
        ./easyrsa build-ca
        ./easyrsa build-server-full ldap.impresso.org nopass

        cp pki/private/ldap.impresso.org.key /etc/ssl/private/
        cp pki/issued/ldap.impresso.org.crt /etc/ssl/certs/
        cp pki/ca.crt pki/ca.impresso.org.crt
        cp pki/ca.impresso.org.crt /usr/share/ca-certificates/mozilla/
        dpkg-reconfigure ca-certificates
