variable "auth_token" {
  description = "This is your Equinix Metal API Auth token"
  type        = string
  sensitive   = true
}

variable "organization_id" {
  description = "Your Equinix Metal Organization Id"
  type        = string
  default     = "null"
}

variable "project_name" {
  default     = "vmware-on-metal-1"
  type        = string
  description = "If 'create_project' is true this will be the project name used."
}

variable "create_project" {
  description = "if true create the Equinix Metal project, if not skip and use the provided project"
  type        = bool
  default     = true
}

variable "project_id" {
  description = "Equinix Metal Project ID to use in case create_project is false"
  type        = string
  default     = "null"
}

variable "private_subnets" {
  description = <<-EOF
  This is the network topology for your vSphere Env
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
  EOF

  type = list(object({
    name                 = string,
    nat                  = bool,
    vsphere_service_type = string,
    routable             = bool,
    cidr                 = string,
    reserved_ip_count    = optional(number)
  }))
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
  type = list(object({
    name                 = string,
    nat                  = bool,
    vsphere_service_type = optional(string),
    routable             = bool,
    ip_count             = number
  }))
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
  type        = string
  default     = "edge-gateway01"
}

variable "esxi_hostname" {
  description = "This is the hostname prefix for your esxi hosts. A number will be added to the end."
  type        = string
  default     = "esx"
}

variable "router_size" {
  description = "This is the size/plan/flavor of your router machine"
  type        = string
  default     = "c3.small.x86"
}

variable "esxi_size" {
  description = "This is the size/plan/flavor of your ESXi machine(s)"
  type        = string
  default     = "c3.medium.x86"
}

variable "facility" {
  description = "This is the Region/Location of your deployment (Must be an IBX facility, Metro will be used if empty)"
  type        = string
  default     = ""
}

variable "metro" {
  description = "This is the Metro Location of your deployment. (Facility will be used if empty)"
  type        = string
  default     = ""
}

variable "router_os" {
  description = "This is the operating System for you router machine (Only Ubuntu 18.04 has been tested)"
  type        = string
  default     = "ubuntu_18_04"
}

variable "vmware_os" {
  description = "This is the version of vSphere that you want to deploy (ESXi 6.5, 6.7, & 7.0 have been tested)"
  type        = string
  default     = "vmware_esxi_7_0"
}

variable "billing_cycle" {
  description = "This is billing cycle to use. The hasn't beend built to allow reserved isntances yet."
  type        = string
  default     = "hourly"
}

variable "esxi_host_count" {
  description = "This is the number of ESXi host you'd like in your cluster."
  type        = number
  default     = 3
}

variable "vcenter_portgroup_name" {
  description = "This is the VM Portgroup you would like vCenter to be deployed to. See 'private_subnets' & 'public_subnets' above. By deploying on a public subnet, you will not need to use the VPN to access vCenter."
  type        = string
  default     = "VM Public Net 1"
}

variable "domain_name" {
  description = "This is the domain to use for internal DNS"
  type        = string
  default     = "metal.local"
}

variable "vpn_user" {
  description = "This is the username for the L2TP VPN"
  type        = string
  default     = "vm_admin"
}

variable "vcenter_datacenter_name" {
  description = "This will be the name of the vCenter Datacenter object."
  type        = string
  default     = "Metal"
}

variable "vcenter_cluster_name" {
  description = "This will be the name of the vCenter Cluster object."
  type        = string
  default     = "Metal-1"
}

variable "vcenter_domain" {
  description = "This will be the vSphere SSO domain."
  type        = string
  default     = "vsphere.local"
}

variable "vcenter_user_name" {
  description = "This will be the admin user for vSphere SSO"
  type        = string
  default     = "Administrator"
}

variable "s3_url" {
  description = "This is the URL endpoint to connect your s3 client to"
  type        = string
  default     = "https://s3.example.com"
}

variable "s3_access_key" {
  description = "This is the access key for your S3 endpoint"
  type        = string
  sensitive   = true
  default     = "S3_ACCESS_KEY"
}

variable "s3_secret_key" {
  description = "This is the secret key for your S3 endpoint"
  type        = string
  sensitive   = true
  default     = "S3_SECRET_KEY"
}

variable "s3_version" {
  description = "S3 API Version (S3v2, S3v4)"
  type        = string
  default     = "S3v4"
}

variable "object_store_tool" {
  description = "Which tool should you use to download objects from the object store? ('mc' and 'gcs' have been tested.)"
  type        = string
  default     = "mc"
}

variable "object_store_bucket_name" {
  description = "This is the name of the bucket on your Object Store"
  type        = string
  default     = "vmware"
}

variable "gcs_key_name" {
  description = "If you are using GCS to download your vCenter ISO this is the name of the GCS key"
  type        = string
  default     = "storage-reader-key.json"
}

variable "path_to_gcs_key" {
  description = "If you are using GCS to download your vCenter ISO this is the absolute path to the GCS key (ex: /home/example/storage-reader-key.json)"
  type        = string
  default     = ""
}

variable "relative_path_to_gcs_key" {
  description = "(Deprecated: use path_to_gcs_key) If you are using GCS to download your vCenter ISO this is the path to the GCS key"
  type        = string
  default     = ""
}

variable "vcenter_iso_name" {
  description = "The name of the vCenter ISO in your Object Store"
  type        = string
}

variable "reservations" {
  description = <<-EOF
  A map of hostnames to reservation ids. Any hostname not defined will use the default behavior of not using a reservation. Mapped values may be UUIDs of reservations, 'next-available', or empty string.

  Warning: Mixing "next-available" and known reservations may result in race conditions. The host requests are submitted at the same time and the "next-available" chosen by the Equinix Metal API may be one of the resources defined by UUID in this list.

  Examples:
  - {"edge-gateway01": "next-available"}
  - {"esx01": "f3bf4e58-99e7-47ef-a0eb-8cbf727bc76f", "esx02": "b3f6b4eb-64b9-4cf1-9e39-f11a8ba9da20"}
  EOF
  type        = map(any)
  default     = {}
}

variable "vcva_deployment_option" {
  description = <<-EOF
  Size of the vCenter appliance: tiny, tiny-lstorage, ..., small, etc.
  Each option has different CPU, memory, and storage requirements.
  For the full list of options, see
  https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vcenter.install.doc/GUID-457EAE1F-B08A-4E64-8506-8A3FA84A0446.html#GUID-457EAE1F-B08A-4E64-8506-8A3FA84A0446__row_5D65E7455996456CBDCB3EF9A7DCDC62__entry__1
  EOF
  type        = string
  default     = "small"
}

variable "update_esxi" {
  description = "if true update the ESXi version before proceeding to vCenter installation"
  type        = bool
  default     = false
}

variable "esxi_update_filename" {
  description = <<-EOF
  The specific update version that your servers will be updated to.
  Note that the Equinix Metal portal and API will still show ESXi 6.5 as the OS but this script adds a tag with the update filename specified below.
  You can check all ESXi update versions/filenames here: https://esxi-patches.v-front.de/
  EOF
  type        = string
  default     = "ESXi-7.0U3d-19482537-standard"
}
