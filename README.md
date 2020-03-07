# VMware on Packet
This repo has Terraform plans to deploy a multi-node vSphere cluster with vSan enabled on Packet. Follow this simple instructions below and you shold be able to go from zero to vSphere in 30 minutes.

## Install Terraform 
Terraform is just a single binary.  Visit their [download page](https://www.terraform.io/downloads.html), choose your operating system, make the binary executable, and move it into your path. 
 
Here is an example for **macOS**: 
```bash 
curl -LO https://releases.hashicorp.com/terraform/0.12.18/terraform_0.12.18_darwin_amd64.zip 
unzip terraform_0.12.18_darwin_amd64.zip 
chmod +x terraform 
sudo mv terraform /usr/local/bin/ 
``` 
 
## Download this project
To download this project and get in the directory, run the following commands:

```bash
git clone https://github.com/c0dyhi11/vmware-on-packet.git
cd vmware-on-packet
```

## Initialize Terraform 
Terraform uses modules to deploy infrastructure. In order to initialize the modules your simply run: `terraform init`. This should download five modules into a hidden directory `.terraform` 

## Setup an S3 compatible object store


You need to use an S3 compatible object store in order to download *closed source* packages such as *vCenter* and the *vSan SDK*. [Minio](http://minio.io) works great for this, which is an open source object store is a workable option.

You will need to layout the S3 structure to look like this:
``` 
https://s3.example.com: 
    | 
    |__ vmware 
        | 
        |__ VMware-VCSA-all-6.7.0-14367737.iso
        | 
        |__ vsanapiutils.py
        | 
        |__ vsanmgmtObjects.py
``` 
These files can be downloaded from [My VMware](http://my.vmware.com).
Once logged in to "My VMware" the download links are as follows:
* [VMware vCenter Server 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VC67U3B&productId=742&rPId=40665) - VVMware vCenter Server Appliance ISO
* [VMware vSAN Management SDK 6.7U3](https://my.vmware.com/group/vmware/details?downloadGroup=VSAN-MGMT-SDK67U3&productId=734) - Virtual SAN Management SDK for Python
 
You will need to find the two individual Python files in the vSAN SDK zip file and place them in the S3 bucket as shown above.
 
## Modify your variables 
There are many variables which can be set to customize your install within `00-vars.tf`. The default variables to bring up a 3 node vSphere cluster and linux router using Packet's [s1.large.x86](https://www.packet.com/cloud/servers/s1-large/). Change each default variable at your own risk. 

There are some variables you must set with a terraform.tfvars files. You need to set `auth_token` & `organization_id` to connect to Packet and the `project_name` which will be created in Packet. We will need an S3 compatible object store to download "Closed Source" packages such as vCenter. You'll provide `s3_url`, `s3_bucket_name`, `s3_access_key`, `s3_secret_key` as well as the vCenter ISO file name as `vcenter_iso_name`. 

 
Here is a quick command plus sample values to start file for you (make sure you adjust the variables to match your environment, pay specail attention that the `vcenter_iso_name` matches whats in your bucket): 
```bash 
cat <<EOF >terraform.tfvars 
cat <<EOF >terraform.tfvars 
auth_token = "cefa5c94-e8ee-4577-bff8-1d1edca93ed8" 
organization_id = "42259e34-d300-48b3-b3e1-d5165cd14169" 
project_name = "vmware-packet-project-1"
s3_url = "https://s3.example.com" 
s3_bucket_name = "vmware" 
s3_access_key = "4fa85962-975f-4650-b603-17f1cb9dee10" 
s3_secret_key = "becf3868-3f07-4dbb-a6d5-eacfd7512b09" 
vcenter_iso_name = "VMware-VCSA-all-6.7.0-XXXXXXX.iso" 
EOF 
``` 

 
## Deploy the Packet vSphere cluster 
 
All there is left to do now is to deploy the cluster: 
```bash 
terraform apply --auto-approve 
``` 
This should end with output similar to this: 
``` 
Apply complete! Resources: 50 added, 0 changed, 0 destroyed. 
 
Outputs: 
 
VPN_Endpoint = 139.178.85.49 
VPN_PSK = @U69neoBD2vlGdHbe@o1 
VPN_Pasword = 0!kfeooo?FaAvyZ2 
VPN_User = vm_admin 
vCenter_Appliance_Root_Password = n4$REf6p*oMo2eYr 
vCenter_FQDN = vcva.packet.local 
vCenter_Password = bzN4UE7m3g$DOf@P 
vCenter_Username = Administrator@vsphere.local 
``` 
 
## Connect to the Environment 
There is an L2TP IPsec VPN setup. There is an L2TP IPsec VPN client for every platform. You'll need to reference your operating system's documentation on how to connect to an L2TP IPsec VPN. 

[MAC how to configure L2TP IPsec VPN](https://support.apple.com/guide/mac-help/set-up-a-vpn-connection-on-mac-mchlp2963/mac)

[Chromebook how to configure LT2P IPsec VPN](https://support.google.com/chromebook/answer/1282338?hl=en)

Make sure to enable all traffic to use the VPN (aka do not enable split tunneling) on your L2TP client.

Some corporate networks block outbound L2TP traffic. If you are experiening issues connecting, you may try a guest network or personal hotspot.


## Cleaning the environement
To clean up a created environment (or a failed one), run `terraform destroy --auto-approve`.

If this does not work for some reason, you can manually delete each of the resources created in Packet (including the project) and then delete your terraform state file, `rm -f terraform.tfstate`.
