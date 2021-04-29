#!/usr/bin/env python3
import json
import ipaddress
import sys


def read_in():
    return {x.strip() for x in sys.stdin}


def main():
    lines = read_in()
    vcenter_ip = None
    options = None
    for line in lines:
        if line:
            options = json.loads(line)
    subnets = json.loads(options["private_subnets"])
    public_subnets = json.loads(options["public_subnets"])
    public_cidrs = json.loads(options["public_cidrs"])
    vcenter_network = options["vcenter_network"]

    for i in range(0, len(public_subnets)):
        public_subnets[i]["cidr"] = public_cidrs[i]
        subnets.append(public_subnets[i])

    for subnet in subnets:
        if subnet["name"] == vcenter_network:
            vcenter_ip = list(ipaddress.ip_network(subnet["cidr"]).hosts())[
                1
            ].compressed
            break

    output = {"vcenter_ip": vcenter_ip}
    sys.stdout.write(json.dumps(output))


if __name__ == "__main__":
    main()
