variable "auth_token" {
  description = "This is your Packet API Auth token. This can also be specified with the TF_VAR_PACKET_AUTH_TOKEN shell environment variable."
  type        = string
}

variable "organization_id" {
  description = "Your Exuinix Metal Organization Id"
  default     = "null"
  type        = string
}

variable "project_name" {
  default = "vmware-on-metal-1"
}

variable "create_project" {
  description = "if true create the packet project, if not skip and use the provided project"
  default     = true
}

variable "project_id" {
  description = "Packet Project ID to use in case create_project is false"
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
  default = [
    {
      "name" : "VM Private Net 1",
      "nat" : true,
      "vsphere_service_type" : "management",
      "routable" : true,
      "cidr" : "172.16.0.0/24",
      "reserved_ip_count" = 100
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
  default = "edge-gateway01"
}

variable "esxi_hostname" {
  default = "esx"
}

variable "router_size" {
  default = "c3.small.x86"
}

variable "esxi_size" {
  default = "c3.medium.x86"
}

variable "facility" {
  default = "ny5"
}

variable "router_os" {
  default = "ubuntu_18_04"
}

variable "vmware_os" {
  default = "vmware_esxi_6_7"
}

variable "billing_cycle" {
  default = "hourly"
}

variable "esxi_host_count" {
  default = 3
}

variable "vcenter_portgroup_name" {
  default = "VM Public Net 1"
}

variable "domain_name" {
  default = "metal.local"
}

variable "vpn_user" {
  default = "vm_admin"
}

variable "vcenter_datacenter_name" {
  default = "Metal"
}

variable "vcenter_cluster_name" {
  default = "Metal-1"
}

variable "vcenter_domain" {
  default = "vsphere.local"
}

variable "vcenter_user_name" {
  default = "Administrator"
}

variable "s3_url" {
  default = "https://s3.example.com"
}

variable "s3_bucket_name" {
  default = "vmware"
}

variable "s3_access_key" {
  default = "S3_ACCESS_KEY"
}

variable "s3_secret_key" {
  default = "S3_SECRET_KEY"
}

variable "s3_boolean" {
  description = "If true use S3 API to download vCenter else use GCS"
  default     = true
}

variable "gcs_bucket_name" {
  default = "vmware"
}

variable "relative_path_to_gcs_key" {
  default = "storage-reader-key.json"
}

variable "s3_version" {
  description = "S3 API Version (S3v2, S3v4)"
  default     = "S3v4"
}

variable "vcenter_iso_name" {
  description = "The name of the vCenter ISO in your Object Store"
  type        = string
}
