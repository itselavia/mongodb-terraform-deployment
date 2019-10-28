#!/usr/bin/env python3

import json
import sys

data = json.load(sys.stdin)

for reservation in data['Reservations']:
    tags = reservation["Instances"][0]["Tags"]
    for tag in tags:
        if tag["Key"] == "Type":
            node_type = tag["Value"]
        if tag["Key"] == "Name":
            node_index = tag["Value"][-1]

if node_type == "primary":
    print(node_type)
else:
    print(node_type + node_index)