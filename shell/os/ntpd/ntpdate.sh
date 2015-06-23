#!/bin/bash

yum install ntpdate -y

echo '0.poll.ntp.org' >> /etc/ntp/step-tickers
sed -i 's/^SYNC_HWCLOCK=no/SYNC_HWCLOCK=yes/' /etc/sysconfig/ntpdate

systemctl status ntpdate
systemctl enable ntpdate
systemctl start ntpdate

#CentOS 6
#chkconfig ntpdate on
#service ntpdate start