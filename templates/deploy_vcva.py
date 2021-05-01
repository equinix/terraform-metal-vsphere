import ipaddress
import os
import sys
import subprocess
import socket
from time import sleep
from pyVmomi import vim
from pyVim import connect
from vars import (
    private_subnets,
    public_subnets,
    public_cidrs,
    esx_passwords,
    vcenter_username,
    sso_password,
    dc_name,
    vcenter_cluster_name,
    vcenter_network,
    domain_name,
)


def get_ssl_thumbprint(host_ip):
    p1 = subprocess.Popen(
        ("echo", "-n"), stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    p2 = subprocess.Popen(
        ("openssl", "s_client", "-connect", "{0}:443".format(host_ip)),
        stdin=p1.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    p3 = subprocess.Popen(
        ("openssl", "x509", "-noout", "-fingerprint", "-sha1"),
        stdin=p2.stdout,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    out = p3.stdout.read()
    ssl_thumbprint = out.split(b"=")[-1].strip()
    return ssl_thumbprint.decode("utf-8")


subnets = private_subnets

for i in range(len(public_cidrs)):
    public_subnets[i]["cidr"] = public_cidrs[i]
    subnets.append(public_subnets[i])
esx = []
for pw in esx_passwords:
    esx.append({"password": pw})

for subnet in subnets:
    if subnet["vsphere_service_type"] == "management":
        esx_ip = list(ipaddress.ip_network(subnet["cidr"]).hosts())[3].compressed
        for i in range(len(esx)):
            esx[i]["private_ip"] = list(ipaddress.ip_network(subnet["cidr"]).hosts())[
                i + 3
            ].compressed
    if subnet["name"] == vcenter_network:
        vcenter_ip = list(ipaddress.ip_network(subnet["cidr"]).hosts())[1].compressed
        gateway_ip = list(ipaddress.ip_network(subnet["cidr"]).hosts())[0].compressed
        prefix_length = int(subnet["cidr"].split("/")[1])

# If there's only one host, extend the datastore with all available disks

if len(esx) == 1:
    print(esx[0]["private_ip"])
    ip = str(esx[0]["private_ip"])
    command = (
        "chmod a+x $HOME/bootstrap/extend_datastore.sh && $HOME/bootstrap/extend_datastore.sh "
        + ip
        + " $HOME/.ssh/esxi_key"
    )
    os.system(command)

os.system(
    "sed -i -e 's/__ESXI_IP__/{}/g' "
    "-e 's/__VCENTER_IP__/{}/g' "
    "-e 's/__VCENTER_GATEWAY__/{}/g' "
    "-e 's/__VCENTER_PREFIX_LENGTH__/{}/g' "
    "$HOME/bootstrap/vcva_template.json".format(
        esx_ip, vcenter_ip, gateway_ip, prefix_length
    )
)

os.system(
    "/mnt/vcsa-cli-installer/lin64/vcsa-deploy install --accept-eula --acknowledge-ceip "
    "--no-esx-ssl-verify $HOME/bootstrap/vcva_template.json"
)

# Connect to vCenter
si = None
for i in range(1, 30):
    try:
        si = connect.SmartConnectNoSSL(
            host=vcenter_ip, user=vcenter_username, pwd=sso_password, port=443
        )
        break
    except Exception:
        sleep(10)
if si is None:
    print("Couldn't connect to vCenter!!!")
    sys.exit(1)

# Create Datacenter in the root folder
folder = si.content.rootFolder
dc = folder.CreateDatacenter(name=dc_name)

# Create cluster config
cluster_config = vim.cluster.ConfigSpecEx()

# Create DRS config
drs_config = vim.cluster.DrsConfigInfo()
drs_config.enabled = True
cluster_config.drsConfig = drs_config

if len(esx) > 2:
    # Create vSan config
    vsan_config = vim.vsan.cluster.ConfigInfo()
    vsan_config.enabled = True
    vsan_config.defaultConfig = vim.vsan.cluster.ConfigInfo.HostDefaultInfo(
        autoClaimStorage=True
    )
    cluster_config.vsanConfig = vsan_config

# Create HA config
if len(esx) > 1:
    ha_config = vim.cluster.DasConfigInfo()
    ha_config.enabled = True
    ha_config.hostMonitoring = vim.cluster.DasConfigInfo.ServiceState.enabled
    ha_config.failoverLevel = 1
    cluster_config.dasConfig = ha_config

# Create the cluster
host_folder = dc.hostFolder
cluster = host_folder.CreateClusterEx(name=vcenter_cluster_name, spec=cluster_config)

# Join hosts to the cluster
for host in esx:
    dns_name = "{}.{}".format(socket.gethostbyaddr(host["private_ip"])[0], domain_name)
    print(
        "Joining host {} with ip {} to the cluster".format(dns_name, host["private_ip"])
    )
    host_connect_spec = vim.host.ConnectSpec()
    host_connect_spec.hostName = dns_name
    host_connect_spec.userName = "root"
    host_connect_spec.password = host["password"]
    host_connect_spec.force = True
    host_connect_spec.sslThumbprint = get_ssl_thumbprint(dns_name)
    cluster.AddHost(spec=host_connect_spec, asConnected=True)
