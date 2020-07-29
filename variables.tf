variable "auth_token" {
}

variable "organization_id" {
}

variable "project_name" {
  default = "vmware-on-packet-1"
}

variable "project_id" {
  default = ""
}

variable "create_project" {
  description = "should terraform create the project? when false the project name must already exist"
  default     = false
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
      "cidr" : "172.16.0.0/24"
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
      "ip_count" : 4
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
  default = "dfw2"
}

variable "router_os" {
  default = "ubuntu_18_04"
}

variable "vmware_os" {
  default = "vmware_esxi_7_0"
}

variable "billing_cycle" {
  default = "hourly"
}

variable "esxi_host_count" {
  default = 3
}

variable "vcenter_portgroup_name" {
  default = "VM Private Net 1"
}

variable "domain_name" {
  default = "packet.local"
}

variable "vpn_user" {
  default = "vm_admin"
}

variable "vcenter_datacenter_name" {
  default = "Packet"
}

variable "vcenter_cluster_name" {
  default = "Packet-1"
}

variable "vcenter_domain" {
  default = "vsphere.local"
}

variable "vcenter_user_name" {
  default = "Administrator"
}

variable "s3_url" {
}

variable "s3_bucket_name" {
}

variable "s3_access_key" {
}

variable "s3_secret_key" {
}

variable "vcenter_iso_name" {
}
