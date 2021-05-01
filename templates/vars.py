#!/usr/bin/python3
import json

# Vars from Terraform in """ so single quotes from Terraform vars don't escape
private_subnets = json.loads("""${private_subnets}""")
private_vlans = json.loads("""${private_vlans}""")
public_subnets = json.loads("""${public_subnets}""")
public_vlans = json.loads("""${public_vlans}""")
public_cidrs = json.loads("""${public_cidrs}""")
esx_passwords = json.loads("""${esx_passwords}""")

domain_name = """${domain_name}"""
vcenter_network = """${vcenter_network}"""
vcenter_fqdn = """${vcenter_fqdn}"""
vcenter_user = """${vcenter_user}"""
vcenter_domain = """${vcenter_domain}"""
vcenter_cluster_name = """${vcenter_cluster_name}"""
metal_token = """${metal_token}"""
vcenter_username = """${vcenter_user}@${vcenter_domain}"""
sso_password = """${sso_password}"""
dc_name = """${dc_name}"""
plan_type = """${plan_type}"""

# vcenter_password is not used
