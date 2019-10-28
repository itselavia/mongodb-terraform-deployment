#!/usr/bin/env python3

import json
import sys

data = json.load(sys.stdin)

for reservation in data['Reservations']:
    private_ip = reservation["Instances"][0]["PrivateIpAddress"]
    tags = reservation["Instances"][0]["Tags"]
    for tag in tags:
        if tag["Key"] == "Name":
            node_index = tag["Value"][-1]
            with open('/etc/hosts', 'a') as f:
                f.writelines('{0} secondary{1}\n'.format(private_ip, node_index))