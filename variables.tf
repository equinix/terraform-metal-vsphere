variable "auth_token" {
  description = "This is your Equinix Metal API Auth token"
  sensitive   = true
  type        = string
}

variable "organization_id" {
  description = "Your Equinix Metal Organization Id"
  default     = "null"
  type        = string
}

variable "project_name" {
  default     = "vmware-on-metal-1"
  description = "If 'create_project' is true this will be the project name used."
}

variable "create_project" {
  description = "if true create the Equinix Metal project, if not skip and use the provided project"
  default     = true
}

variable "project_id" {
  description = "Equinix Metal Project ID to use in case create_project is false"
  default     = "null"
}

/*
Valid vsphere_service_types are:
    faultToleranceLogging
    vmotion
    vSphereReplication
    vSphereReplicationNFC
    vSphereProvisioning
    vsan
    management

The subnet name "Management" is reserved for ESXi hosts.
Whichever subnet is labeled with vsphere_service_type: management will share a vLan with ESXi hosts.
*/

variable "private_subnets" {
  description = "This is the network topology for your vSphere Env"
  default = [
    {
      "name" : "VM Private Net 1",
      "nat" : true,
      "vsphere_service_type" : "management",
      "routable" : true,
      "cidr" : "172.16.0.0/24",
      "reserved_ip_count" : 100
    },
    {
      "name" : "vMotion",
      "nat" : false,
      "vsphere_service_type" : "vmotion",
      "routable" : false,
      "cidr" : "172.16.1.0/24"
    },
    {
      "name" : "vSAN",
      "nat" : false,
      "vsphere_service_type" : "vsan",
      "routable" : false,
      "cidr" : "172.16.2.0/24"
    }
  ]
}

variable "public_subnets" {
  description = "This will dynamically create public subnets in vSphere"
  default = [
    {
      "name" : "VM Public Net 1",
      "nat" : false,
      "vsphere_service_type" : null,
      "routable" : true,
      "ip_count" : 8
    }
  ]
}

variable "router_hostname" {
  description = "This is the hostname for the router."
  default     = "edge-gateway01"
}

variable "esxi_hostname" {
  description = "This is the hostname prefix for your esxi hosts. A number will be added to the end."
  default     = "esx"
}

variable "router_size" {
  description = "This is the size/plan/flavor of your router machine"
  default     = "c3.small.x86"
}

variable "esxi_size" {
  description = "This is the size/plan/flavor of your ESXi machine(s)"
  default     = "c3.medium.x86"
}

variable "facility" {
  description = "This is the Region/Location of your deployment (Must be an IBX facility, Metro will be used if empty)"
  default     = ""
}

variable "metro" {
  description = "This is the Metro Location of your deployment. (Facility will be used if empty)"
  default     = ""
}

variable "router_os" {
  description = "This is the operating System for you router machine (Only Ubuntu 18.04 has been tested)"
  default     = "ubuntu_18_04"
}

variable "vmware_os" {
  description = "This is the version of vSphere that you want to deploy (ESXi 6.5, 6.7, & 7.0 have been tested)"
  default     = "vmware_esxi_7_0"
}

variable "billing_cycle" {
  description = "This is billing cycle to use. The hasn't beend built to allow reserved isntances yet."
  default     = "hourly"
}

variable "esxi_host_count" {
  description = "This is the number of ESXi host you'd like in your cluster."
  default     = 3
}

variable "vcenter_portgroup_name" {
  description = "This is the VM Portgroup you would like vCenter to be deployed to. See 'private_subnets' & 'public_subnets' above. By deploying on a public subnet, you will not need to use the VPN to access vCenter."
  default     = "VM Public Net 1"
}

variable "domain_name" {
  description = "This is the domain to use for internal DNS"
  default     = "metal.local"
}

variable "vpn_user" {
  description = "This is the username for the L2TP VPN"
  default     = "vm_admin"
}

variable "vcenter_datacenter_name" {
  description = "This will be the name of the vCenter Datacenter object."
  default     = "Metal"
}

variable "vcenter_cluster_name" {
  description = "This will be the name of the vCenter Cluster object."
  default     = "Metal-1"
}

variable "vcenter_domain" {
  description = "This will be the vSphere SSO domain."
  default     = "vsphere.local"
}

variable "vcenter_user_name" {
  description = "This will be the admin user for vSphere SSO"
  default     = "Administrator"
}

variable "s3_url" {
  description = "This is the URL endpoint to connect your s3 client to"
  default     = "https://s3.example.com"
}

variable "s3_access_key" {
  description = "This is the access key for your S3 endpoint"
  sensitive   = true
  default     = "S3_ACCESS_KEY"
}

variable "s3_secret_key" {
  description = "This is the secret key for your S3 endpoint"
  sensitive   = true
  default     = "S3_SECRET_KEY"
}

variable "s3_version" {
  description = "S3 API Version (S3v2, S3v4)"
  default     = "S3v4"
}

variable "object_store_tool" {
  description = "Which tool should you use to download objects from the object store? ('mc' and 'gcs' have been tested.)"
  default     = "mc"
}

variable "object_store_bucket_name" {
  description = "This is the name of the bucket on your Object Store"
  default     = "vmware"
}

variable "gcs_key_name" {
  description = "If you are using GCS to download your vCenter ISO this is the name of the GCS key"
  default     = "storage-reader-key.json"
}

variable "path_to_gcs_key" {
  description = "If you are using GCS to download your vCenter ISO this is the absolute path to the GCS key (ex: /home/example/storage-reader-key.json)"
  default     = ""
}

variable "relative_path_to_gcs_key" {
  description = "(Deprecated: use path_to_gcs_key) If you are using GCS to download your vCenter ISO this is the path to the GCS key"
  default     = ""
}

variable "vcenter_iso_name" {
  description = "The name of the vCenter ISO in your Object Store"
  type        = string
}
