#!/bin/bash

#
# Bootstraps a Jenkins slave using Conjur hostfactory
#
# This script takes 2 arguments
# 1. The Conjur hostfactory token
# 2. The ID of the instance, this will show up in Conjur as "host/myid". This ID must be unique.
#
# Example Usage:
# bash /opt/conjur-bootstrap.sh 3tsccy121wvsqm1xejtjdurh28dmc5s8v633vckrswrtg8q1j7gwre i-f3432b1f
#

set -e

tokenName="{{ locals[:tName] }}"

if [ $tokenName == 'conjurBastionHostFactoryToken' ]; then
# Configure iptables
/sbin/iptables -t nat -C POSTROUTING -o eth0 -s 10.0.0.0/24 -j MASQUERADE 2> /dev/null || /sbin/iptables -t nat -A POSTROUTING -o eth0 -s 10.0.0.0/24 -j MASQUERADE
/sbin/iptables-save > /etc/sysconfig/iptables
# Configure ip forwarding and redirects
echo 1 >  /proc/sys/net/ipv4/ip_forward && echo 0 >  /proc/sys/net/ipv4/conf/eth0/send_redirects
mkdir -p /etc/sysctl.d/
cat <<EOF > /etc/sysctl.d/nat.conf
net.ipv4.ip_forward = 1
net.ipv4.conf.eth0.send_redirects = 0
EOF
else
route add default gw {{ "Fn::GetAtt": [ "conjurBastionServer", "PrivateIp" ] }}
fi

host_token={{ ref("${tokenName}") }}
host_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
host_identity=/var/conjur/host-identity.json

CONJUR_HOST_IDENTITY_VERSION=v1.0.1
CONJUR_SSH_VERSION=v1.2.5

export HOME=/root

echo "Inserting hostfactory token and ID into $host_identity"
sed -i "s/%%HOST_TOKEN%%/${host_token}/" ${host_identity}
sed -i "s/%%HOST_ID%%/${host_id}/" ${host_identity}

echo "Running chef-solo conjur-host-identity]"
chef-solo -r https://github.com/conjur-cookbooks/conjur-host-identity/releases/download/${CONJUR_HOST_IDENTITY_VERSION}/conjur-host-identity-${CONJUR_HOST_IDENTITY_VERSION}.tar.gz -j ${host_identity}

echo "Running chef-solo recipe[conjur-ssh]"
chef-solo -r https://github.com/conjur-cookbooks/conjur-ssh/releases/download/${CONJUR_SSH_VERSION}/conjur-ssh-${CONJUR_SSH_VERSION}.tar.gz -o conjur-ssh

echo "All set!"
