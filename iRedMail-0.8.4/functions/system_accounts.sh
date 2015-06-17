#!/usr/bin/env bash

# Author: Zhang Huangbin <zhb _at_ iredmail.org>

# Add required system accounts

add_user_vmail()
{
    ECHO_DEBUG "Create HOME folder for vmail user."

    homedir="$(dirname $(echo ${VMAIL_USER_HOME_DIR} | sed 's#/$##'))"
    [ -L ${homedir} ] && rm -f ${homedir}
    [ -d ${homedir} ] || mkdir -p ${homedir}
    [ -d ${STORAGE_MAILBOX_DIR} ] || mkdir -p ${STORAGE_MAILBOX_DIR}

    ECHO_DEBUG "Create system account: ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} (${VMAIL_USER_UID}:${VMAIL_USER_GID})."

    # vmail/vmail must has the same UID/GID on all supported Linux/BSD
    # distributions, required by cluster environment. e.g. GlusterFS.
    if [ X"${DISTRO}" == X"FREEBSD" ]; then
        pw groupadd -g ${VMAIL_USER_GID} -n ${VMAIL_GROUP_NAME} 2>/dev/null
        pw useradd -m \
            -u ${VMAIL_USER_UID} \
            -g ${VMAIL_GROUP_NAME} \
            -s ${SHELL_NOLOGIN} \
            -d ${VMAIL_USER_HOME_DIR} \
            -n ${VMAIL_USER_NAME} 2>/dev/null
    elif [ X"${DISTRO}" == X'OPENBSD' ]; then
        groupadd -g ${VMAIL_USER_GID} ${VMAIL_GROUP_NAME} 2>/dev/null
        # Don't use -m to create new home directory
        useradd \
            -u ${VMAIL_USER_UID} \
            -g ${VMAIL_GROUP_NAME} \
            -s ${SHELL_NOLOGIN} \
            -d ${VMAIL_USER_HOME_DIR} \
            ${VMAIL_USER_NAME} 2>/dev/null
    else
        # Note: on openSUSE, package 'postfix-mysql' will create vmail:vmail with uid/gid=303.
        groupadd -g ${VMAIL_USER_GID} ${VMAIL_GROUP_NAME} 2>/dev/null
        useradd -m \
            -u ${VMAIL_USER_UID} \
            -g ${VMAIL_GROUP_NAME} \
            -s ${SHELL_NOLOGIN} \
            -d ${VMAIL_USER_HOME_DIR} \
            ${VMAIL_USER_NAME} 2>/dev/null
    fi
    rm -f ${VMAIL_USER_HOME_DIR}/.* 2>/dev/null

    # Set permission for exist home directory.
    if [ -d ${VMAIL_USER_HOME_DIR} ]; then
        chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${VMAIL_USER_HOME_DIR}
        chmod -R 0700 ${VMAIL_USER_HOME_DIR}
    fi

    ECHO_DEBUG "Create directory to store user sieve rule files: ${SIEVE_DIR}."
    mkdir -p ${SIEVE_DIR} && \
    chown -R ${VMAIL_USER_NAME}:${VMAIL_GROUP_NAME} ${SIEVE_DIR} && \
    chmod -R 0700 ${SIEVE_DIR}

    cat >> ${TIP_FILE} <<EOF
Mail Storage:
    - Root directory: ${VMAIL_USER_HOME_DIR}
    - Mailboxes: ${STORAGE_MAILBOX_DIR}
    - Backup scripts and copies: ${BACKUP_DIR}

EOF

    echo 'export status_add_user_vmail="DONE"' >> ${STATUS_FILE}
}

add_user_iredadmin()
{
    ECHO_DEBUG "Create system account: ${IREDADMIN_USER_NAME}:${IREDADMIN_GROUP_NAME} (${IREDADMIN_USER_UID}:${IREDADMIN_USER_GID})"

    # Low privilege user used to run iRedAdmin.
    if [ X"${DISTRO}" == X'FREEBSD' ]; then
        pw groupadd -g ${IREDADMIN_USER_GID} -n ${IREDADMIN_USER_NAME} 2>/dev/null
        pw useradd -m \
            -u ${IREDADMIN_USER_GID} \
            -g ${IREDADMIN_GROUP_NAME} \
            -s ${SHELL_NOLOGIN} \
            -d ${IREDADMIN_HOME_DIR} \
            -n ${IREDADMIN_USER_NAME} 2>/dev/null
    else
        groupadd -g ${IREDADMIN_USER_GID} ${IREDADMIN_GROUP_NAME} 2>/dev/null
        useradd -m \
            -u ${IREDADMIN_USER_UID} \
            -g ${IREDADMIN_GROUP_NAME} \
            -s ${SHELL_NOLOGIN} \
            -d ${IREDADMIN_HOME_DIR} \
            ${IREDADMIN_USER_NAME} 2>/dev/null
    fi

    echo 'export status_add_user_iredadmin="DONE"' >> ${STATUS_FILE}
}

add_user_iredapd()
{
    ECHO_DEBUG "Create system account: ${IREDAPD_DAEMON_USER}:${IREDAPD_DAEMON_GROUP} (${IREDAPD_DAEMON_USER_UID}:${IREDAPD_DAEMON_USER_GID})."

    # Low privilege user used to run iRedAPD daemon.
    if [ X"${DISTRO}" == X'FREEBSD' ]; then
        pw groupadd -g ${IREDAPD_DAEMON_USER_GID} -n ${IREDAPD_DAEMON_GROUP} 2>/dev/null
        pw useradd -m \
            -u ${IREDAPD_DAEMON_USER_GID} \
            -g ${IREDAPD_DAEMON_GROUP} \
            -s ${SHELL_NOLOGIN} \
            -d ${IREDAPD_HOME_DIR} \
            -n ${IREDAPD_DAEMON_USER} 2>/dev/null
    else
        groupadd -g ${IREDAPD_DAEMON_USER_GID} ${IREDAPD_DAEMON_GROUP} 2>/dev/null
        useradd -m \
            -u ${IREDAPD_DAEMON_USER_UID} \
            -g ${IREDAPD_DAEMON_GROUP} \
            -s ${SHELL_NOLOGIN} \
            -d ${IREDAPD_HOME_DIR} \
            ${IREDAPD_DAEMON_USER} 2>/dev/null
    fi

    echo 'export status_add_user_iredapd="DONE"' >> ${STATUS_FILE}
}

add_required_users()
{
    ECHO_INFO "Create required system accounts: vmail, iredapd, iredadmin."
    check_status_before_run add_user_vmail
    check_status_before_run add_user_iredadmin
    check_status_before_run add_user_iredapd

    echo 'export status_add_required_users="DONE"' >> ${STATUS_FILE}
}
