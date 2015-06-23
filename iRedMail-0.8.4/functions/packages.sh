#!/usr/bin/env bash

# Author: Zhang Huangbin <zhb _at_ iredmail.org>

#---------------------------------------------------------------------
# This file is part of iRedMail, which is an open source mail server
# solution for Red Hat(R) Enterprise Linux, CentOS, Debian and Ubuntu.
#
# iRedMail is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# iRedMail is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with iRedMail.  If not, see <http://www.gnu.org/licenses/>.
#---------------------------------------------------------------------

install_all()
{
    ALL_PKGS=''
    ENABLED_SERVICES=''
    DISABLED_SERVICES=''
    PKG_SCRIPTS=''  # OpenBSD only

    ###########################
    # Enable syslog or rsyslog.
    #
    if [ X"${DISTRO}" == X'RHEL' ]; then
        # RHEL/CENTOS/Scientific
        if [ -x ${DIR_RC_SCRIPTS}/syslog ]; then
            ENABLED_SERVICES="syslog ${ENABLED_SERVICES}"
        elif [ -x ${DIR_RC_SCRIPTS}/rsyslog ]; then
            ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
        fi
        DISABLED_SERVICES="${DISABLED_SERVICES} exim"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # Debian.
        ENABLED_SERVICES="network syslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"DEBIAN" ]; then
        # Debian.
        ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"UBUNTU" ]; then
        # Ubuntu >= 9.10.
        ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"GENTOO" ]; then
        ENABLED_SERVICES="syslog-ng ${ENABLED_SERVICES}"
        gentoo_add_use_flags 'net-nds/openldap' 'crypt ipv6 ssl tcpd -overlays perl sasl syslog'
        gentoo_add_use_flags 'dev-db/mysql' 'berkdb community perl ssl big-tables cluster'
        gentoo_add_use_flags 'dev-db/postgresql-server' 'nls pam doc perl python xml'
    fi

    #################################################
    # Backend: OpenLDAP, MySQL, PGSQL and extra packages.
    #
    if [ X"${BACKEND}" == X"OPENLDAP" ]; then
        # OpenLDAP server & client.
        ENABLED_SERVICES="${ENABLED_SERVICES} ${OPENLDAP_RC_SCRIPT_NAME} ${MYSQL_RC_SCRIPT_NAME}"

        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} openldap${PKG_ARCH} openldap-clients${PKG_ARCH} openldap-servers${PKG_ARCH} mysql-server${PKG_ARCH} mysql${PKG_ARCH}"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} openldap2 openldap2-client mysql-community-server mysql-community-server-client"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-ldap slapd ldap-utils libnet-ldap-perl mysql-server mysql-client"

        elif [ X"${DISTRO}" == X"GENTOO" ]; then
            ALL_PKGS="${ALL_PKGS} openldap mysql"

        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            if [ X"${BACKEND_ORIG}" == X'OPENLDAP' ]; then
                ALL_PKGS="${ALL_PKGS} openldap-server"
                PKG_SCRIPTS="${PKG_SCRIPTS} ${OPENLDAP_RC_SCRIPT_NAME}"
            fi

            ALL_PKGS="${ALL_PKGS} cyrus-sasl--ldap openldap-client mysql-server mysql-client"
            PKG_SCRIPTS="${PKG_SCRIPTS} ${MYSQL_RC_SCRIPT_NAME}"

        fi
    elif [ X"${BACKEND}" == X"MYSQL" ]; then
        # MySQL server & client.
        ENABLED_SERVICES="${ENABLED_SERVICES} ${MYSQL_RC_SCRIPT_NAME}"
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} mysql-server${PKG_ARCH} mysql${PKG_ARCH}"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql${PKG_ARCH}"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} mysql-community-server mysql-community-server-client"

            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} postfix-mysql"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            # MySQL server and client.
            ALL_PKGS="${ALL_PKGS} mysql-server mysql-client postfix-mysql"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X"YES" ] && ALL_PKGS="${ALL_PKGS} libapache2-mod-auth-mysql"

        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} mysql"

        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} mysql-client cyrus-sasl--mysql mysql-server"
            PKG_SCRIPTS="${PKG_SCRIPTS} ${MYSQL_RC_SCRIPT_NAME}"

        fi
    elif [ X"${BACKEND}" == X"PGSQL" ]; then
        ENABLED_SERVICES="${ENABLED_SERVICES} ${PGSQL_RC_SCRIPT_NAME}"

        # PGSQL server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-server${PKG_ARCH} postgresql-contrib${PKG_ARCH}"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X'YES' -o X"${USE_CLUEBRINGER}" == X'YES' ] && \
                ALL_PKGS="${ALL_PKGS} mod_auth_pgsql${PKG_ARCH}"

        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-server postgresql-contrib postfix-postgresql"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            # postgresql-contrib provides extension 'dblink' used in Roundcube password plugin.
            ALL_PKGS="${ALL_PKGS} postgresql postgresql-client postgresql-contrib postfix-pgsql"

        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-server mod_auth_pgsql"

        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-client cyrus-sasl--pgsql postgresql-server postgresql-contrib"
            PKG_SCRIPTS="${PKG_SCRIPTS} ${PGSQL_RC_SCRIPT_NAME}"
        fi
    fi

    #################
    # Apache and PHP.
    #
    ENABLED_SERVICES="${ENABLED_SERVICES} ${HTTPD_RC_SCRIPT_NAME}"
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} httpd${PKG_ARCH} mod_ssl${PKG_ARCH} php${PKG_ARCH} php-common${PKG_ARCH} php-gd${PKG_ARCH} php-xml${PKG_ARCH} php-mysql${PKG_ARCH} php-ldap${PKG_ARCH} php-pgsql${PKG_ARCH}"
        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} php-imap${PKG_ARCH} libmcrypt${PKG_ARCH} php-mcrypt${PKG_ARCH} php-mhash${PKG_ARCH} php-mbstring${PKG_ARCH}"
        fi

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # Apache
        ALL_PKGS="${ALL_PKGS} apache2-prefork apache2-mod_php5"

        # PHP
        ALL_PKGS="${ALL_PKGS} php5-dom php5-fileinfo php5-gettext php5-iconv php5-intl php5-json php5-ldap php5-mbstring php5-mcrypt"

        [ X"${BACKEND}" == X'OPENLDAP' -o X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} php5-mysql"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} php5-pgsql"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} apache2 apache2-mpm-prefork apache2.2-common libapache2-mod-php5 php5-cli php5-imap php5-gd php5-mcrypt php5-mysql php5-ldap php5-pgsql"

        # Authentication modules
        ALL_PKGS="${ALL_PKGS} libapache2-mod-auth-mysql libapache2-mod-auth-pgsql"

        if [ X"${DISTRO_CODENAME}" == X'squeeze' ]; then
            ALL_PKGS="${ALL_PKGS} php5-mhash"
        fi

        if [ X"${DISTRO_CODENAME}" != X'squeeze' ]; then
            if [ X"${BACKEND}" == X"OPENLDAP" ]; then
                ALL_PKGS="${ALL_PKGS} php-net-ldap2"
            fi
        fi

    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} apache php"
        gentoo_add_use_flags 'dev-libs/apr-util' 'ldap'
        gentoo_add_use_flags 'www-servers/apache' 'ssl doc ldap suexec'
        gentoo_add_make_conf 'APACHE2_MODULES' 'actions alias auth_basic authn_alias authn_anon authn_dbm authn_default authn_file authz_dbm authz_default authz_groupfile authz_host authz_owner authz_user autoindex cache cgi cgid dav dav_fs dav_lock deflate dir disk_cache env expires ext_filter file_cache filter headers include info log_config logio mem_cache mime mime_magic negotiation rewrite setenvif speling status unique_id userdir usertrack vhost_alias auth_digest authn_dbd log_forensic proxy proxy_ajp proxy_balancer proxy_connect proxy_ftp proxy_http proxy_scgi substitute version'
        gentoo_add_make_conf 'APACHE2_MPMS' 'prefork'

        gentoo_add_use_flags 'dev-lang/php' 'berkdb bzip2 cli crypt ctype fileinfo filter hash iconv ipv6 json nls phar posix readline session simplexml ssl tokenizer unicode xml zlib apache2 calendar -cdb cgi cjk curl curlwrappers doc flatfile fpm ftp gd gmp imap inifile intl kerberos ldap ldap-sasl mhash mysql mysqli mysqlnd odbc pdo postgres snmp soap sockets spell sqlite sqlite3 suhosin tidy truetype wddx xmlreader xmlrpc xmlwriter xpm xsl zip'

        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql"
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        ALL_PKGS="${ALL_PKGS} php php-bz2 php-imap php-mcrypt php-gd"

        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} php-ldap php-mysql php-mysqli"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} php-mysql php-mysqli"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} php-pgsql"
    fi

    ###############
    # Postfix.
    #
    ENABLED_SERVICES="${ENABLED_SERVICES} ${POSTFIX_RC_SCRIPT_NAME}"
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} postfix${PKG_ARCH}"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        # On openSUSE, postfix already has ldap_table support.
        ALL_PKGS="${ALL_PKGS} postfix"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix postfix-pcre"
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} postfix"
        #gentoo_unmask_package 'mail-mta/ssmtp'
        gentoo_add_use_flags 'mail-mta/postfix' 'ipv6 pam ssl cdb dovecot-sasl hardened ldap ldap-bind mbox mysql postgres sasl'
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        #PKG_SCRIPTS: Postfix will flush the queue when startup, so we should
        #             start amavisd before postfix since Amavisd is content
        #             filter.
        if [ X"${BACKEND}" == X'OPENLDAP' ]; then
            ALL_PKGS="${ALL_PKGS} postfix--ldap"
        elif [ X"${BACKEND}" == X'MYSQL' ]; then
            ALL_PKGS="${ALL_PKGS} postfix--mysql"
        elif [ X"${BACKEND}" == X'PGSQL' ]; then
            ALL_PKGS="${ALL_PKGS} postfix--pgsql"
        fi
    fi

    # Policyd.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        if [ X"${USE_POLICYD}" == X'YES' ]; then
            ALL_PKGS="${ALL_PKGS} policyd${PKG_ARCH}"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${POLICYD_RC_SCRIPT_NAME}"
        else
            ALL_PKGS="${ALL_PKGS} cluebringer"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${CLUEBRINGER_RC_SCRIPT_NAME}"
        fi
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        if [ X"${USE_POLICYD}" == X'YES' ]; then
            ALL_PKGS="${ALL_PKGS} policyd"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${POLICYD_RC_SCRIPT_NAME}"
        else
            ALL_PKGS="${ALL_PKGS} cluebringer"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${CLUEBRINGER_RC_SCRIPT_NAME}"
        fi

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        if [ X"${USE_CLUEBRINGER}" == X'YES' ]; then
            ALL_PKGS="${ALL_PKGS} postfix-cluebringer postfix-cluebringer-webui"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${CLUEBRINGER_RC_SCRIPT_NAME}"

            if [ X"${BACKEND}" == X"OPENLDAP" -o X"${BACKEND}" == X"MYSQL" ]; then
                ALL_PKGS="${ALL_PKGS} postfix-cluebringer-mysql"
            elif [ X"${BACKEND}" == X"PGSQL" ]; then
                ALL_PKGS="${ALL_PKGS} postfix-cluebringer-pgsql"
            fi
        else
            ALL_PKGS="${ALL_PKGS} postfix-policyd"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${POLICYD_RC_SCRIPT_NAME}"
        fi

    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} policyd"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${POLICYD_RC_SCRIPT_NAME}"
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        # No port available.
        :
    fi

    # Dovecot.
    ENABLED_SERVICES="${ENABLED_SERVICES} ${DOVECOT_RC_SCRIPT_NAME}"
    if [ X"${DISTRO}" == X"RHEL" ]; then
        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot${PKG_ARCH} dovecot-sieve${PKG_ARCH} dovecot-managesieve${PKG_ARCH}"
        elif [ X"${DISTRO_VERSION}" == X"6" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot${PKG_ARCH} dovecot-managesieve${PKG_ARCH} dovecot-pigeonhole${PKG_ARCH}"
        fi

        # We use Dovecot SASL auth instead of saslauthd
        DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} dovecot21"

        if [ X"${BACKEND}" == X"MYSQL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot21-backend-mysql"
        elif [ X"${BACKEND}" == X"PGSQL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot21-backend-pgsql"
        fi

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} dovecot-imapd dovecot-pop3d"

        if [ X"${DISTRO_CODENAME}" != X'squeeze' ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-managesieved dovecot-sieve"

            if [ X"${BACKEND}" == X"OPENLDAP" ]; then
                ALL_PKGS="${ALL_PKGS} dovecot-ldap dovecot-mysql"
            elif [ X"${BACKEND}" == X"MYSQL" ]; then
                ALL_PKGS="${ALL_PKGS} dovecot-mysql"
            elif [ X"${BACKEND}" == X"PGSQL" ]; then
                ALL_PKGS="${ALL_PKGS} dovecot-pgsql"
            fi
        fi
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} dovecot"
        DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"
        gentoo_add_use_flags 'net-mail/dovecot' 'bzip2 ipv6 maildir pam ssl zlib caps doc kerberos ldap managesieve mbox mdbox mysql postgres sdbox sieve sqlite suid'

    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        ALL_PKGS="${ALL_PKGS} dovecot dovecot-pigeonhole"
        PKG_SCRIPTS="${PKG_SCRIPTS} ${DOVECOT_RC_SCRIPT_NAME}"

        if [ X"${BACKEND}" == X'OPENLDAP' ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-ldap dovecot-mysql"
        elif [ X"${BACKEND}" == X'MYSQL' ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-mysql"
        elif [ X"${BACKEND}" == X'PGSQL' ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-postgresql"
        fi

        DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"
    fi

    # Amavisd-new & ClamAV & Altermime.
    ENABLED_SERVICES="${ENABLED_SERVICES} ${CLAMAV_CLAMD_RC_SCRIPT_NAME} ${AMAVISD_RC_SCRIPT_NAME}"
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} clamd${PKG_ARCH} clamav${PKG_ARCH} clamav-db${PKG_ARCH} spamassassin${PKG_ARCH} altermime${PKG_ARCH} perl-LDAP.noarch perl-Mail-SPF.noarch perl-Mail-SPF-Query.noarch"

        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} amavisd-new${PKG_ARCH} perl-IO-Compress.noarch"
        else
            ALL_PKGS="${ALL_PKGS} amavisd-new.noarch"
        fi

        if [ X"${BACKEND}" == X'PGSQL' ]; then
            ALL_PKGS="${ALL_PKGS} perl-DBD-Pg"
        fi

        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} perl-Mail-SPF amavisd-new clamav spamassassin altermime"

        # openSUSE-12.2. package 'clamav-db' is not required in openSUSE-12.3.
        [ X"${DISTRO_CODENAME}" == X'mantis' ] && ALL_PKGS="${ALL_PKGS} clamav-db"

        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} perl-ldap perl-DBD-mysql"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} perl-DBD-mysql"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} perl-DBD-Pg"

        ENABLED_SERVICES="${ENABLED_SERVICES} ${CLAMAV_FRESHCLAMD_RC_SCRIPT_NAME}"
        DISABLED_SERVICES="${DISABLED_SERVICES} clamav-milter spamd spampd"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new libcrypt-openssl-rsa-perl libmail-dkim-perl clamav-freshclam clamav-daemon spamassassin altermime arj zoo nomarch cpio lzop cabextract p7zip rpm unrar-free ripole libmail-spf-perl"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${CLAMAV_FRESHCLAMD_RC_SCRIPT_NAME}"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new spamassassin clamav altermime Mail-SPF"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamd"

        gentoo_add_use_flags 'mail-filter/amavisd-new' 'dkim ldap mysql postgres razor snmp spamassassin'
        gentoo_add_use_flags 'mail-filter/spamassassin' 'berkdb ipv6 ssl doc ldap mysql postgres sqlite'
        gentoo_add_use_flags 'app-antivirus/clamav' 'bzip2 iconv ipv6'
        gentoo_add_use_flags 'net-analyzer/net-snmp' 'bzip2 ipv6 ssl tcpd zlib perl'

    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} p5-ldap p5-DBD-mysql"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} p5-DBD-mysql"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} p5-DBD-Pg"

        ALL_PKGS="${ALL_PKGS} rpm2cpio amavisd-new p5-Mail-SPF p5-Mail-SpamAssassin clamav"
        PKG_SCRIPTS="${PKG_SCRIPTS} ${CLAMAV_CLAMD_RC_SCRIPT_NAME} ${CLAMAV_FRESHCLAMD_RC_SCRIPT_NAME} ${AMAVISD_RC_SCRIPT_NAME} ${POSTFIX_RC_SCRIPT_NAME}"
    fi

    # phpPgAdmin
    if [ X"${USE_PHPPGADMIN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            :
        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} phpPgAdmin"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} phppgadmin"
        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} phppgadmin"
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} phpPgAdmin"
        fi
    fi

    # Roundcube
    if [ X"${USE_RCM}" == X"YES" ]; then
        if [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} roundcubemail"
        fi
    fi

    # phpMyAdmin
    if [ X"${USE_PHPMYADMIN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X'SUSE' ]; then
            ALL_PKGS="${ALL_PKGS} phpMyAdmin"
        elif [ X"${DISTRO}" == X'DEBIAN' -o X"${DISTRO}" == X'UBUNTU' ]; then
            ALL_PKGS="${ALL_PKGS} phpmyadmin"
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} phpMyAdmin"
        fi
    fi

    # phpLDAPadmin
    if [ X"${USE_PHPLDAPADMIN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X'DEBIAN' -o X"${DISTRO}" == X'UBUNTU' ]; then
            ALL_PKGS="${ALL_PKGS} phpldapadmin"
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} phpldapadmin"
        fi
    fi

    ############
    # iRedAPD.
    #
    # Don't append 'iredapd' to ${ENABLED_SERVICES} since we don't have
    # RC script ready in early stage.

    if [ X"${DISTRO}" == X"RHEL" ]; then
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} python-ldap${PKG_ARCH} MySQL-python${PKG_ARCH}"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} MySQL-python${PKG_ARCH}"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} python-psycopg2${PKG_ARCH}"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} python-ldap python-mysql"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} python-mysql"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} python-psycopg2"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} python-ldap python-mysqldb"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} python-mysqldb"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} python-psycopg2"

    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} python-ldap mysql-python"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} mysql-python"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} psycopg"

    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} py-ldap py-mysql"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} py-mysql"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} py-psycopg2"
        PKG_SCRIPTS="${PKG_SCRIPTS} iredapd"
    fi

    # iRedAdmin.
    # Force install all dependence to help customers install iRedAdmin-Pro.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} python-jinja2${PKG_ARCH} python-webpy.noarch mod_wsgi${PKG_ARCH}"

    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} apache2-mod_wsgi python-jinja2 python-xml python-web.py"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} libapache2-mod-wsgi python-jinja2 python-netifaces python-webpy"
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} jinja webpy mod_wsgi"

        gentoo_add_use_flags 'dev-python/jinja' 'examples i18n vim-syntax'
        # Don't use python-3
        gentoo_mask_package '<=dev-lang/python-3.0'
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        ALL_PKGS="${ALL_PKGS} py-jinja2 py-webpy py-flup"
    fi

    #############
    # Awstats.
    #
    if [ X"${USE_AWSTATS}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} awstats.noarch"
        elif [ X"${DISTRO}" == X"SUSE" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        elif [ X"${DISTRO}" == X'GENTOO' ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
            gentoo_add_use_flags 'www-misc/awstats' 'ipv6 geoip'
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            # No port available.
            :
        fi
    fi

    #### Fail2ban ####
    if [ X"${USE_FAIL2BAN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X'OPENBSD' ]; then
            # No port available.
            :
        else
            ALL_PKGS="${ALL_PKGS} fail2ban"
            ENABLED_SERVICES="${ENABLED_SERVICES} ${FAIL2BAN_RC_SCRIPT_NAME}"

            if [ X"${DISTRO}" == X"RHEL" ]; then
                DISABLED_SERVICES="${DISABLED_SERVICES} shorewall"
            fi
        fi
    fi


    ############################
    # Misc packages & services.
    #
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2${PKG_ARCH} acl${PKG_ARCH} patch${PKG_ARCH} tmpwatch${PKG_ARCH} crontabs.noarch dos2unix${PKG_ARCH} logwatch"
        if [ X"${DISTRO_VERSION}" == X"5" ]; then
            ALL_PKGS="${ALL_PKGS} vixie-cron${PKG_ARCH}"
        fi
        ENABLED_SERVICES="${ENABLED_SERVICES} crond"
    elif [ X"${DISTRO}" == X"SUSE" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl patch cron tmpwatch dos2unix logwatch"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl patch cron tofrodos logwatch"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    elif [ X"${DISTRO}" == X'GENTOO' ]; then
        ALL_PKGS="${ALL_PKGS} dos2unix logwatch"
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        ALL_PKGS="${ALL_PKGS} bzip2"
    fi

    # Disable Ubuntu firewall rules, we have iptables init script and rule file.
    [ X"${DISTRO}" == X"UBUNTU" ] && export DISABLED_SERVICES="${DISABLED_SERVICES} ufw"

    #
    # ---- End Ubuntu 10.04 special. ----
    #

    export ALL_PKGS ENABLED_SERVICES

    # Install all packages.
    install_all_pkgs()
    {
        if [ X"${DISTRO}" == X'SUSE' ]; then
            rpm -e patterns-openSUSE-minimal_base-conflicts &>/dev/null
            rpm -e exim &>/dev/null
        fi

        # Install all packages.
        if [ X"${DISTRO}" == X'OPENBSD' ]; then
            ECHO_INFO "PKG_PATH: ${PKG_PATH}"
            ECHO_INFO "Installing packages:${ALL_PKGS}"
        fi
        eval ${install_pkg} ${ALL_PKGS}

        echo 'export status_install_all_pkgs="DONE"' >> ${STATUS_FILE}
    }

    # Enable/Disable services.
    enable_all_services()
    {
        # Enable services.
        eval ${enable_service} ${ENABLED_SERVICES} >/dev/null

        # Disable services.
        if [ X"${DISTRO}" == X'OPENBSD' ]; then
            echo "pkg_scripts='${PKG_SCRIPTS}'" >> ${RC_CONF_LOCAL}
            ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
            ln -sf /usr/local/bin/python2.7-2to3 /usr/local/bin/2to3
            ln -sf /usr/local/bin/python2.7-config /usr/local/bin/python-config
            ln -sf /usr/local/bin/pydoc2.7  /usr/local/bin/pydoc
        else
            eval ${disable_service} ${DISABLED_SERVICES} >/dev/null
        fi

        if [ X"${DISTRO}" == X"SUSE" ]; then
            eval ${disable_service} SuSEfirewall2_setup SuSEfirewall2_init >/dev/null
        fi

        echo 'export status_enable_all_services="DONE"' >> ${STATUS_FILE}
    }

    check_status_before_run install_all_pkgs
    check_status_before_run enable_all_services
}
