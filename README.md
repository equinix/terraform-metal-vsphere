# VMware on Equinix Metal

[![Experimental](https://img.shields.io/badge/Stability-Experimental-red.svg)](https://github.com/packethost/standards#about-uniform-standards)
[![Slack Status](https://slack.equinixmetal.com/badge.svg)](https://slack.equinixmetal.com/)
[![integration](https://github.com/equinix/terraform-metal-vsphere/actions/workflows/integration.yml/badge.svg)](https://github.com/equinix/terraform-metal-vsphere/actions/workflows/integration.yml)

This repo has Terraform plans to deploy a multi-node vSphere cluster with vSan enabled on Equinix Metal. Follow this simple instructions below and you should be able to go from zero to vSphere in 30 minutes.

## Install Terraform

Terraform is just a single binary.  Visit their [download page](https://www.terraform.io/downloads.html), choose your operating system, make the binary executable, and move it into your path.

Here is an example for **macOS**:

```bash
curl -LO https://releases.hashicorp.com/terraform/0.14.8/terraform_0.14.8_darwin_amd64.zip
unzip terraform_0.14.8_darwin_amd64.zip
chmod +x terraform 
sudo mv terraform /usr/local/bin/
```

## Download this project

To download this project and get in the directory, run the following commands:

```bash
git clone https://github.com/equinix/terraform-metal-vsphere.git
cd terraform-metal-vsphere
```

## Initialize Terraform

Terraform uses modules to deploy infrastructure. In order to initialize the modules your simply run: `terraform init -upgrade`. This should download five modules into a hidden directory `.terraform`

## Setup your object store
We need an object store to download *closed source* packages such as *vCenter* and the *vSan SDK*.
### S3 Compatible
[Minio](http://minio.io) works great for this, which is an open source object store. Or you can use AWS S3.

The following settings will be needed in your `terraform.tfvars` to use S3
```console
object_store_tool        = "s3"
object_store_bucket_name = "bucket_name/folder"
s3_url                   = "https://s3.example.com"
s3_access_key            = "4fa85962-975f-4650-b603-17f1cb9dee10"
s3_secret_key            = "becf3868-3f07-4dbb-a6d5-eacfd7512b09"
s3_version               = "S3v4"
```

### Google Cloud Storage (GCS)
We also have the option to use Google Cloud Storage (GCS). The setup will use a service account with Storage Reader permissions to download the needed files.

The following settings will be needed in your `terraform.tfvars` to use GCS
```console
object_store_tool        = "gcs"
object_store_bucket_name = "bucket_name/folder"
relative_path_to_gcs_key = "storage-reader-key.json"
```

## Upload files to your Object Store
You will need to layout the object store structure to look like this:

```console
Object Store Root: 
    | 
    |__ Bucket_Name 
        | 
        |__ VMware-VCSA-all-7.0.3-18700403.iso
        | 
        |__ vsanapiutils.py
        | 
        |__ vsanmgmtObjects.py
```

Your VMware ISO name may vary depending on which build you download. If you choose VMWare 7.0, be sure to use version 7.0u3 or greater, per [VMSA-2021-0020.1](https://www.vmware.com/security/advisories/VMSA-2021-0020.html).

These files can be downloaded from [My VMware](http://my.vmware.com).

Once logged in to "My VMware" the download links are as follows:

* [VMware vCenter Server 7.0U3](https://customerconnect.vmware.com/en/group/vmware/evalcenter?p=vsphere-eval-7&source=evap) - VMware vCenter Server Appliance ISO
* [VMware vSAN Management SDK 7.0U3](https://code.vmware.com/web/sdk/7.0%20U3/vsan-python ) - Virtual SAN Management SDK for Python

You will need to find the Python files in the vSAN SDK zip file (`binding/vsanmgmtObjects.py`, `samplecode/vsanapiutils.py`) and place them in your object store bucket as shown above. Make sure the version of the Python SDK matches the version of vCenter Server and the version of the ESXi image chosen.

## Modify your variables

There are many variables which can be set to customize your install within `vars.tf`. The default variables to bring up a 3 node vSphere cluster and linux router using Equinix Metal's [c3.medium.x86](https://metal.equinix.com/product/servers/). Change each default variable at your own risk.

There are some variables you must set with a `terraform.tfvars` files. You need to set `auth_token` & `organization_id` to connect to Equinix Metal and the `project_name` which will be created in Equinix Metal. We will to setup you object store to download "Closed Source" packages such as vCenter. You'll provide the needed variables as described above as well as the vCenter ISO file name as `vcenter_iso_name`.

Here is a quick command plus sample values (assuming an S3 object store) to start file for you (make sure you adjust the variables to match your environment, pay special attention that the `vcenter_iso_name` matches whats in your bucket):

```bash
cat <<EOF >terraform.tfvars
auth_token = "cefa5c94-e8ee-4577-bff8-1d1edca93ed8"
organization_id = "42259e34-d300-48b3-b3e1-d5165cd14169"
project_name = "vmware-metal-project-1"
s3_url = "https://s3.example.com"
object_store_bucket_name = "vmware"
s3_access_key = "4fa85962-975f-4650-b603-17f1cb9dee10"
s3_secret_key = "becf3868-3f07-4dbb-a6d5-eacfd7512b09"
vcenter_iso_name = "VMware-VCSA-all-7.0.3-XXXXXXX.iso"
EOF
```

## Upgrading ESXi version

For some servers on Equinix Metal, only an older version of ESXi is available (6.5). You can upgrade such servers to a more recent version by setting `update_esxi = true`, and specifying an `esxi_update_filename` (refer to [VMware ESXi Patch Tracker](https://esxi-patches.v-front.de/) for latest update versions). The upgrade will be performed right after a server has been provisioned, and before vCenter Server installation starts.

```bash
cat <<EOF >>terraform.tfvars
update_esxi = true
esxi_update_filename = "ESXi-7.0U3d-19482537-standard"
EOF
```

A standalone Terraform script for ESXi upgrade is available [here](https://github.com/enkelprifti98/packet-esxi-6-7).

## Deploy the Equinix Metal vSphere cluster

All there is left to do now is to deploy the cluster:

```bash
terraform apply --auto-approve 
```

This should end with output similar to this:

```console
Apply complete! Resources: 36 added, 0 changed, 0 destroyed.

Outputs:

bastion_host = "147.75.47.205"
ssh_key_path = "$HOME/.ssh/anthos-packet-project-1-g6oty-key"
vcenter_fqdn = "vcva.metal.local"
vcenter_ip = "139.178.83.226"
vcenter_password = "4!wz2HbQ*CRtgS8A"
vcenter_root_password = "9SKyaj5B@99O!3Le"
vcenter_username = "Administrator@vsphere.local"
vpn_endpoint = "147.75.47.205"
vpn_pasword = "!f*NhVj0uSehmm0k"
vpn_psk = "?j*ISFUae563Sq4I@P28"
vpn_user = "vm_admin"
```

## Connect to the Environment

There is an L2TP IPsec VPN setup. There is an L2TP IPsec VPN client for every platform. You'll need to reference your operating system's documentation on how to connect to an L2TP IPsec VPN.

[MAC how to configure L2TP IPsec VPN](https://support.apple.com/guide/mac-help/set-up-a-vpn-connection-on-mac-mchlp2963/mac)

[Chromebook how to configure LT2P IPsec VPN](https://support.google.com/chromebook/answer/1282338?hl=en)

Make sure to enable all traffic to use the VPN (aka do not enable split tunneling) on your L2TP client.

Some corporate networks block outbound L2TP traffic. If you are experiencing issues connecting, you may try a guest network or personal hotspot.

## Cleaning the environment

To clean up a created environment (or a failed one), run `terraform destroy --auto-approve`.

If this does not work for some reason, you can manually delete each of the resources created in Equinix Metal (including the project) and then delete your terraform state file, `rm -f terraform.tfstate`.
