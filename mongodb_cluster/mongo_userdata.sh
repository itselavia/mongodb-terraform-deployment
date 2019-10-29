#!/bin/bash
set -x

exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
apt-get update

echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config
systemctl restart ssh

wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | apt-key add -
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list

apt-get update
apt-get install -y mongodb-org unzip python3-distutils jq build-essential python3-dev
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
rm -f get-pip.py

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

cat >> /etc/mongod.conf <<EOL

security:
  keyFile: /opt/mongodb/keyFile

replication:
  replSetName: ${replica_set_name}

EOL

chown ubuntu:ubuntu /etc/mongod.conf

cat >> /etc/systemd/system/mongod.service <<EOL

[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target

[Service]
User=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target

EOL

chown ubuntu:ubuntu /etc/systemd/system/mongod.service

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
rm -rf awscli-bundle.zip
/usr/bin/python3 ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

PRIMARY_PUBLIC_IP=$(aws ec2 describe-instances --filters "Name=tag:Type,Values=primary" "Name=instance-state-name,Values=running" --region ${aws_region} | jq .Reservations[0].Instances[0].PrivateIpAddress --raw-output)
echo "$PRIMARY_PUBLIC_IP primary" >> /etc/hosts

while [ ! -f /home/ubuntu/populate_hosts_file.py ]
do
  sleep 2
done

while [ ! -f /home/ubuntu/parse_instance_tags.py ]
do
  sleep 2
done

while [ ! -f /home/ubuntu/keyFile ]
do
  sleep 2
done

mkdir -p /opt/mongodb
mv /home/ubuntu/keyFile /opt/mongodb
chown mongodb:mongodb /opt/mongodb/keyFile
chmod 600 /opt/mongodb/keyFile

mv /home/ubuntu/populate_hosts_file.py /populate_hosts_file.py
mv /home/ubuntu/parse_instance_tags.py /parse_instance_tags.py

chmod +x populate_hosts_file.py
chmod +x parse_instance_tags.py
aws ec2 describe-instances --filters "Name=tag:Type,Values=secondary" "Name=instance-state-name,Values=running" --region ${aws_region} | jq . | ./populate_hosts_file.py ${replica_set_name} ${mongo_database} ${mongo_username} ${mongo_password}

INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id --silent)
HOSTNAME=$(aws ec2 describe-instances --instance-id $INSTANCE_ID --region ${aws_region} | jq . | ./parse_instance_tags.py)
hostnamectl set-hostname $HOSTNAME

MONGO_NODE_TYPE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Type" --region ${aws_region} | jq .Tags[0].Value --raw-output)

systemctl enable mongod.service

service mongod start
service mongod restart
service mongod status

if [ $MONGO_NODE_TYPE == "primary" ]; then

  sleep 15
  mongo < cluster_setup.js
  service mongod restart
  sleep 15
  mongo < user_setup.js
  rm -f user_setup.js
fi

service mongod restart