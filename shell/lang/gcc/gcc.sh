#!/bin/bash

#if [ -z "$( egrep "CentOS|Redhat" /etc/issue)" ]; then
#	echo 'Only for Redhat or CentOS'
#	exit
#fi

yum install -y gcc gcc-c++ make automake autoconf patch
