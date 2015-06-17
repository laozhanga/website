
ldap_generate_populate_ldif()
{
    ECHO_DEBUG "Generate LDIF file used to populate LDAP tree."
    cat > ${LDAP_INIT_LDIF} <<EOF
dn: ${LDAP_SUFFIX}
objectclass: dcObject
objectclass: organization
dc: ${LDAP_SUFFIX_MAJOR}
o: ${LDAP_SUFFIX_MAJOR}

dn: ${LDAP_BINDDN}
objectClass: person
objectClass: shadowAccount
objectClass: top
cn: ${VMAIL_USER_NAME}
sn: ${VMAIL_USER_NAME}
uid: ${VMAIL_USER_NAME}
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd "${LDAP_BINDPW}")

dn: ${LDAP_ADMIN_DN}
objectClass: person
objectClass: shadowAccount
objectClass: top
cn: ${VMAIL_DB_ADMIN_USER}
sn: ${VMAIL_DB_ADMIN_USER}
uid: ${VMAIL_DB_ADMIN_USER}
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd "${LDAP_ADMIN_PW}")

dn: ${LDAP_BASEDN}
objectClass: Organization
o: ${LDAP_BASEDN_NAME}

dn: ${LDAP_ADMIN_BASEDN}
objectClass: Organization
o: ${LDAP_ATTR_DOMAINADMIN_DN_NAME}

dn: ${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_MAILDOMAIN}
${LDAP_ATTR_DOMAIN_RDN}: ${FIRST_DOMAIN}
${LDAP_ATTR_MTA_TRANSPORT}: ${TRANSPORT}
${LDAP_ATTR_ACCOUNT_STATUS}: ${LDAP_STATUS_ACTIVE}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_MAIL}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SENDER_BCC}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_RECIPIENT_BCC}

dn: ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_OU}
objectClass: top
ou: ${LDAP_ATTR_GROUP_USERS}

dn: ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_GROUPS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_OU}
objectClass: top
ou: ${LDAP_ATTR_GROUP_GROUPS}

dn: ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_ALIASES},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_OU}
objectClass: top
ou: ${LDAP_ATTR_GROUP_ALIASES}

dn: ${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_EXTERNALS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: ${LDAP_OBJECTCLASS_OU}
objectClass: top
ou: ${LDAP_ATTR_GROUP_EXTERNALS}

dn: ${LDAP_ATTR_USER_RDN}=${FIRST_USER}@${FIRST_DOMAIN},${LDAP_ATTR_GROUP_RDN}=${LDAP_ATTR_GROUP_USERS},${LDAP_ATTR_DOMAIN_RDN}=${FIRST_DOMAIN},${LDAP_BASEDN}
objectClass: inetOrgPerson
objectClass: shadowAccount
objectClass: amavisAccount
objectClass: ${LDAP_OBJECTCLASS_MAILUSER}
objectClass: top
cn: ${FIRST_USER}
sn: ${FIRST_USER}
uid: ${FIRST_USER}
givenName: ${FIRST_USER}
${LDAP_ATTR_USER_RDN}: ${FIRST_USER}@${FIRST_DOMAIN}
${LDAP_ATTR_ACCOUNT_STATUS}: ${LDAP_STATUS_ACTIVE}
${LDAP_ATTR_USER_STORAGE_BASE_DIRECTORY}: ${STORAGE_BASE_DIR}
mailMessageStore: ${STORAGE_NODE}/$( hash_domain ${FIRST_DOMAIN})/$( hash_maildir ${FIRST_USER} )
homeDirectory: ${STORAGE_MAILBOX_DIR}/$( hash_domain ${FIRST_DOMAIN})/$( hash_maildir ${FIRST_USER} )
${LDAP_ATTR_USER_QUOTA}: 104857600
${LDAP_ATTR_USER_PASSWD}: $(gen_ldap_passwd "${FIRST_USER_PASSWD}")
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_MAIL}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_INTERNAL}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_DOVEADM}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SMTP}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SMTPS}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_POP3}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_POP3S}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_IMAP}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_IMAPS}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_DELIVER}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_LDA}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_FORWARD}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SENDER_BCC}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_RECIPIENT_BCC}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_MANAGESIEVE}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_MANAGESIEVES}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SIEVE}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SIEVES}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_DISPLAYED_IN_ADDRBOOK}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_SHADOW_ADDRESS}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_LIB_STORAGE}
${LDAP_ENABLED_SERVICE}: ${LDAP_SERVICE_DOMAIN_ADMIN}
${LDAP_ATTR_DOMAIN_GLOBALADMIN}: yes
EOF
}

ldap_server_config()
{
    ldap_generate_populate_ldif
    export LDAP_ROOTPW_SSHA="$(gen_ldap_passwd ${LDAP_ROOTPW})"

    if [ X"${BACKEND_ORIG}" == X'LDAPD' ]; then
        . ${FUNCTIONS_DIR}/ldapd.sh

        check_status_before_run ldapd_config
    else
        . ${FUNCTIONS_DIR}/openldap.sh

        check_status_before_run openldap_config && \
        check_status_before_run openldap_data_initialize

    fi
}
