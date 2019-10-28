#!/bin/bash
set -x

exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
yum -y update

echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
service sshd restart

yum -y install curl iputils check-update gcc wget libcurl openssl

chmod 400 /home/ec2-user/id_rsa