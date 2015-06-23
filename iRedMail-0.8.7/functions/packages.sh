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

    # OpenBSD: Hard-code package versions
    export OB_PHP_VER='5.4.24'
    export OB_POSTFIX_VER='2.11.0'
    export OB_OPENLDAP_VER='2.4.38'

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
    elif [ X"${DISTRO}" == X"DEBIAN" ]; then
        # Debian.
        ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
    elif [ X"${DISTRO}" == X"UBUNTU" ]; then
        # Ubuntu >= 9.10.
        ENABLED_SERVICES="rsyslog ${ENABLED_SERVICES}"
    fi

    #################################################
    # Backend: OpenLDAP, MySQL, PGSQL and extra packages.
    #
    if [ X"${BACKEND}" == X"OPENLDAP" ]; then
        # OpenLDAP server & client.
        ENABLED_SERVICES="${ENABLED_SERVICES} ${OPENLDAP_RC_SCRIPT_NAME} ${MYSQL_RC_SCRIPT_NAME}"

        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} openldap${PKG_ARCH} openldap-clients${PKG_ARCH} openldap-servers${PKG_ARCH} mysql-server${PKG_ARCH} mysql${PKG_ARCH}"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-ldap slapd ldap-utils libnet-ldap-perl mysql-server mysql-client"

        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            if [ X"${BACKEND_ORIG}" == X'OPENLDAP' ]; then
                ALL_PKGS="${ALL_PKGS} openldap-server-${OB_OPENLDAP_VER}"
                PKG_SCRIPTS="${PKG_SCRIPTS} ${OPENLDAP_RC_SCRIPT_NAME}"
            fi

            ALL_PKGS="${ALL_PKGS} openldap-client mysql-server mysql-client"
            PKG_SCRIPTS="${PKG_SCRIPTS} ${MYSQL_RC_SCRIPT_NAME}"

        fi
    elif [ X"${BACKEND}" == X'MYSQL' ]; then
        # MySQL server & client.
        ENABLED_SERVICES="${ENABLED_SERVICES} ${MYSQL_RC_SCRIPT_NAME}"
        if [ X"${DISTRO}" == X"RHEL" ]; then
            if [ X"${USE_LOCAL_MYSQL_SERVER}" == X'YES' ]; then
                ALL_PKGS="${ALL_PKGS} mysql-server${PKG_ARCH}"
            fi
            ALL_PKGS="${ALL_PKGS} mysql${PKG_ARCH}"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            # MySQL server and client.
            if [ X"${USE_LOCAL_MYSQL_SERVER}" == X'YES' ]; then
                if [ X"${BACKEND_ORIG}" == X'MARIADB' ]; then
                    ALL_PKGS="${ALL_PKGS} mariadb-server mariadb-client"
                else
                    ALL_PKGS="${ALL_PKGS} mysql-server mysql-client"
                fi
            fi

            ALL_PKGS="${ALL_PKGS} postfix-mysql libapache2-mod-auth-mysql"

        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            if [ X"${USE_LOCAL_MYSQL_SERVER}" == X'YES' ]; then
                ALL_PKGS="${ALL_PKGS} mysql-server"
                PKG_SCRIPTS="${PKG_SCRIPTS} ${MYSQL_RC_SCRIPT_NAME}"
            fi
            ALL_PKGS="${ALL_PKGS} mysql-client"
        fi
    elif [ X"${BACKEND}" == X"PGSQL" ]; then
        ENABLED_SERVICES="${ENABLED_SERVICES} ${PGSQL_RC_SCRIPT_NAME}"

        # PGSQL server & client.
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-server${PKG_ARCH} postgresql-contrib${PKG_ARCH}"

            # For Awstats.
            [ X"${USE_AWSTATS}" == X'YES' -o X"${USE_CLUEBRINGER}" == X'YES' ] && \
                ALL_PKGS="${ALL_PKGS} mod_auth_pgsql${PKG_ARCH}"

        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            # postgresql-contrib provides extension 'dblink' used in Roundcube password plugin.
            ALL_PKGS="${ALL_PKGS} postgresql postgresql-client postgresql-contrib postfix-pgsql libapache2-mod-auth-pgsql"

        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} postgresql-client postgresql-server postgresql-contrib"
            PKG_SCRIPTS="${PKG_SCRIPTS} ${PGSQL_RC_SCRIPT_NAME}"
        fi
    fi

    #################
    # Apache and PHP.
    #
    ENABLED_SERVICES="${ENABLED_SERVICES} ${HTTPD_RC_SCRIPT_NAME}"
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} httpd${PKG_ARCH} mod_ssl${PKG_ARCH} php${PKG_ARCH} php-common${PKG_ARCH} php-gd${PKG_ARCH} php-xml${PKG_ARCH} php-mysql${PKG_ARCH} php-ldap${PKG_ARCH} php-pgsql${PKG_ARCH} php-imap${PKG_ARCH} php-mbstring${PKG_ARCH} php-pecl-apc${PKG_ARCH}"

    elif [ X"${DISTRO}" == X'DEBIAN' -o X"${DISTRO}" == X'UBUNTU' ]; then
        ALL_PKGS="${ALL_PKGS} libapache2-mod-php5 php5-imap php5-json php5-gd php5-mcrypt php5-curl mcrypt php-apc"
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} php5-ldap php5-mysql"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} php5-mysql"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} php5-pgsql"
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        ALL_PKGS="${ALL_PKGS} php-${OB_PHP_VER} php-bz2-${OB_PHP_VER} php-imap-${OB_PHP_VER} php-mcrypt-${OB_PHP_VER} php-gd-${OB_PHP_VER} pecl-APC"

        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} php-ldap-${OB_PHP_VER} php-mysql-${OB_PHP_VER} php-mysqli-${OB_PHP_VER} php-pdo_mysql-${OB_PHP_VER}"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} php-mysql-${OB_PHP_VER} php-mysqli-${OB_PHP_VER} php-pdo_mysql-${OB_PHP_VER}"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} php-pgsql-${OB_PHP_VER} php-pdo_pgsql-${OB_PHP_VER}"
    fi

    ###############
    # Postfix.
    #
    ENABLED_SERVICES="${ENABLED_SERVICES} ${POSTFIX_RC_SCRIPT_NAME}"
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} postfix${PKG_ARCH}"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix postfix-pcre"
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        #PKG_SCRIPTS: Postfix will flush the queue when startup, so we should
        #             start amavisd before postfix since Amavisd is content
        #             filter.
        if [ X"${BACKEND}" == X'OPENLDAP' ]; then
            ALL_PKGS="${ALL_PKGS} postfix-${OB_POSTFIX_VER}-ldap"
        elif [ X"${BACKEND}" == X'MYSQL' ]; then
            ALL_PKGS="${ALL_PKGS} postfix-${OB_POSTFIX_VER}-mysql"
        elif [ X"${BACKEND}" == X'PGSQL' ]; then
            ALL_PKGS="${ALL_PKGS} postfix-${OB_POSTFIX_VER}-pgsql"
        fi
    fi

    # Policyd.
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} cluebringer perl-DBD-MySQL${PKG_ARCH} perl-DBD-Pg${PKG_ARCH}"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${CLUEBRINGER_RC_SCRIPT_NAME}"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} postfix-cluebringer"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${CLUEBRINGER_RC_SCRIPT_NAME}"

        if [ X"${BACKEND}" == X"OPENLDAP" -o X"${BACKEND}" == X"MYSQL" ]; then
            if [ X"${BACKEND_ORIG}" != X'MARIADB' ]; then
                ALL_PKGS="${ALL_PKGS} postfix-cluebringer-mysql"
            fi
        elif [ X"${BACKEND}" == X"PGSQL" ]; then
            ALL_PKGS="${ALL_PKGS} postfix-cluebringer-pgsql"
        fi
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        # No port available.
        :
    fi

    # Dovecot.
    ENABLED_SERVICES="${ENABLED_SERVICES} ${DOVECOT_RC_SCRIPT_NAME}"
    if [ X"${DISTRO}" == X"RHEL" ]; then
        ALL_PKGS="${ALL_PKGS} dovecot${PKG_ARCH} dovecot-managesieve${PKG_ARCH} dovecot-pigeonhole${PKG_ARCH}"

        # We use Dovecot SASL auth instead of saslauthd
        DISABLED_SERVICES="${DISABLED_SERVICES} saslauthd"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-managesieved dovecot-sieve"

        if [ X"${BACKEND}" == X"OPENLDAP" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-ldap dovecot-mysql"
        elif [ X"${BACKEND}" == X"MYSQL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-mysql"
        elif [ X"${BACKEND}" == X"PGSQL" ]; then
            ALL_PKGS="${ALL_PKGS} dovecot-pgsql"
        fi

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
        ALL_PKGS="${ALL_PKGS} clamd${PKG_ARCH} clamav${PKG_ARCH} clamav-db${PKG_ARCH} spamassassin${PKG_ARCH} altermime${PKG_ARCH} perl-LDAP.noarch perl-Mail-SPF.noarch amavisd-new.noarch"

        if [ X"${BACKEND}" == X'PGSQL' ]; then
            ALL_PKGS="${ALL_PKGS} perl-DBD-Pg"
        fi

        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} amavisd-new libcrypt-openssl-rsa-perl libmail-dkim-perl clamav-freshclam clamav-daemon spamassassin altermime arj zoo nomarch cpio lzop cabextract p7zip rpm unrar-free ripole libmail-spf-perl"
        ENABLED_SERVICES="${ENABLED_SERVICES} ${CLAMAV_FRESHCLAMD_RC_SCRIPT_NAME}"
        DISABLED_SERVICES="${DISABLED_SERVICES} spamassassin"

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
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} phppgadmin"
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} phpPgAdmin"
        fi
    fi

    # Roundcube
    if [ X"${USE_RCM}" == X"YES" ]; then
        if [ X"${DISTRO}" == X'OPENBSD' ]; then
            if [ X"${RCM_USE_SOURCE}" != X'YES' ]; then
                ALL_PKGS="${ALL_PKGS} roundcubemail"
            fi

            ALL_PKGS="${ALL_PKGS} php-pspell"

            # MySQL driver for PHP, required by Roundcube.
            [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} php-pdo_mysql"
            [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} php-pdo_mysql"
            [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} php-pdo_pgsql"
        fi
    fi

    # phpMyAdmin
    if [ X"${USE_PHPMYADMIN}" == X"YES" ]; then
        if [ X"${DISTRO}" == X'DEBIAN' -o X"${DISTRO}" == X'UBUNTU' ]; then
            ALL_PKGS="${ALL_PKGS} phpmyadmin"
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} phpMyAdmin"
        fi
    fi

    # phpLDAPadmin
    if [ X"${USE_PHPLDAPADMIN}" == X'YES' ]; then
        if [ X"${DISTRO}" == X'DEBIAN' -o X"${DISTRO}" == X'UBUNTU' ]; then
            if [ X"${DISTRO_CODENAME}" == X'wheezy' \
                -o X"${DISTRO_CODENAME}" == X'precise' ]; then
                ALL_PKGS="${ALL_PKGS} phpldapadmin"
            fi
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

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        [ X"${BACKEND}" == X'OPENLDAP' ] && ALL_PKGS="${ALL_PKGS} python-ldap python-mysqldb"
        [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} python-mysqldb"
        [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} python-psycopg2"

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

    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} libapache2-mod-wsgi python-jinja2 python-netifaces python-webpy"

    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        ALL_PKGS="${ALL_PKGS} py-jinja2 py-webpy py-flup"
    fi

    #############
    # Awstats.
    #
    if [ X"${USE_AWSTATS}" == X"YES" ]; then
        if [ X"${DISTRO}" == X"RHEL" ]; then
            ALL_PKGS="${ALL_PKGS} awstats.noarch mod_auth_mysql${PKG_ARCH}"
        elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
            ALL_PKGS="${ALL_PKGS} awstats"
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            ALL_PKGS="${ALL_PKGS} awstats"

            [ X"${BACKEND}" == X'OPENLDAP' -o X"${BACKEND}" == X'LDAPD' ] && ALL_PKGS="${ALL_PKGS} mod_auth_ldap"
            [ X"${BACKEND}" == X'MYSQL' ] && ALL_PKGS="${ALL_PKGS} mod_auth_mysql"
            [ X"${BACKEND}" == X'PGSQL' ] && ALL_PKGS="${ALL_PKGS} mod_auth_pgsql"
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
        ENABLED_SERVICES="${ENABLED_SERVICES} crond"
    elif [ X"${DISTRO}" == X"DEBIAN" -o X"${DISTRO}" == X"UBUNTU" ]; then
        ALL_PKGS="${ALL_PKGS} bzip2 acl patch cron tofrodos logwatch"
        ENABLED_SERVICES="${ENABLED_SERVICES} cron"
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        ALL_PKGS="${ALL_PKGS} bzip2"
    fi

    # Disable Ubuntu firewall rules, we have iptables init script and rule file.
    [ X"${DISTRO}" == X"UBUNTU" ] && export DISABLED_SERVICES="${DISABLED_SERVICES} ufw"

    export ALL_PKGS ENABLED_SERVICES

    # Install all packages.
    install_all_pkgs()
    {
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
        if [ X"${DISTRO}" != X'OPENBSD' ]; then
            eval ${disable_service} ${DISABLED_SERVICES} >/dev/null
        fi

        echo 'export status_enable_all_services="DONE"' >> ${STATUS_FILE}
    }

    after_package_installation()
    {
        if [ X"${DISTRO}" == X'RHEL' ]; then
            # Copy DNS related libs to chrooted Postfix directory, so that Postfix
            # can correctly resolve IP address under chroot.
            for i in '/lib' '/lib64'; do
                ls $i/*nss* &>/dev/null
                ret1=$?
                ls $i/*reso* &>/dev/null
                ret2=$?

                if [ X"${ret1}" == X'0' -o X"${ret2}" == X'0' ]; then
                    mkdir -p ${POSTFIX_CHROOT_DIR}${i}
                    cp ${i}/*nss* ${i}/*reso* ${POSTFIX_CHROOT_DIR}${i}/
                fi
            done
        elif [ X"${DISTRO}" == X'OPENBSD' ]; then
            # Create symbol links for Python.
            echo "pkg_scripts='${PKG_SCRIPTS}'" >> ${RC_CONF_LOCAL}
            ln -sf /usr/local/bin/python2.7 /usr/local/bin/python
            ln -sf /usr/local/bin/python2.7-2to3 /usr/local/bin/2to3
            ln -sf /usr/local/bin/python2.7-config /usr/local/bin/python-config
            ln -sf /usr/local/bin/pydoc2.7  /usr/local/bin/pydoc
        fi

        echo 'export status_after_package_installation="DONE"' >> ${STATUS_FILE}
    }

    check_status_before_run install_all_pkgs
    check_status_before_run enable_all_services
    check_status_before_run after_package_installation
}
