#!/usr/bin/env python3

import json
import sys
import os
import time

data = json.load(sys.stdin)

replica_set_name = sys.argv[1]
mongo_database = sys.argv[2]
mongo_username = sys.argv[3]
mongo_pasword = sys.argv[4]

config = {"_id": replica_set_name, "members": [{ "_id": 0, "host": "primary:27017", "priority": 1000 }]}

secondary_nodes = []

for reservation in data['Reservations']:
    private_ip = reservation["Instances"][0]["PrivateIpAddress"]
    tags = reservation["Instances"][0]["Tags"]
    for tag in tags:
        if tag["Key"] == "Name":
            node_index = tag["Value"][-1]
            config["members"].append({"_id": int(node_index), "host": "secondary{0}:27017".format(node_index), "priority": 0.5})
            with open('/etc/hosts', 'a') as f:
                secondary_nodes.append(["secondary{0}".format(node_index), False])
                f.writelines('{0} secondary{1}\n'.format(private_ip, node_index))

allPassed = False

while allPassed != True:
    time.sleep(5)
    for index, node in enumerate(secondary_nodes):
        response = os.system("ping -c 1 -w5 " + node[0] + " > /dev/null 2>&1")
        if response == 0:
            secondary_nodes[index][1] = True
    
    print(secondary_nodes)
    if all(node[1] == True for node in secondary_nodes):
        allPassed = True

with open('/cluster_setup.js', 'a') as f:
    f.writelines("sleep(15000);\n")
    f.writelines("rs.initiate({0})".format(config))
    f.writelines(";\nsleep(15000);\n")

with open('/user_setup.js', 'a') as f:
    f.writelines("db = db.getSiblingDB('{0}');\n".format(mongo_database))
    f.writelines("db.createUser( {{user: '{0}', pwd: '{1}', roles: [{{ role: 'root', db: '{2}' }}] }});\n".format(mongo_username, mongo_pasword, mongo_database))