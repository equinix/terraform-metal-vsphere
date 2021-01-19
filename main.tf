provider "metal" {
  auth_token = var.auth_token
}

resource "metal_project" "new_project" {
  name            = var.project_name
  organization_id = var.organization_id
}

resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "metal_ssh_key" "ssh_pub_key" {
  name       = var.project_name
  public_key = chomp(tls_private_key.ssh_key_pair.public_key_openssh)
}

resource "metal_reserved_ip_block" "ip_blocks" {
  count      = length(var.public_subnets)
  project_id = metal_project.new_project.id
  facility   = var.facility
  quantity   = element(var.public_subnets.*.ip_count, count.index)
}

resource "metal_reserved_ip_block" "esx_ip_blocks" {
  count      = var.esxi_host_count
  project_id = metal_project.new_project.id
  facility   = var.facility
  quantity   = 8
}

resource "metal_vlan" "private_vlans" {
  count       = length(var.private_subnets)
  facility    = var.facility
  project_id  = metal_project.new_project.id
  description = jsonencode(element(var.private_subnets.*.name, count.index))
}

resource "metal_vlan" "public_vlans" {
  count       = length(var.public_subnets)
  facility    = var.facility
  project_id  = metal_project.new_project.id
  description = jsonencode(element(var.public_subnets.*.name, count.index))
}
data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.py")
  vars = {
    private_subnets = jsonencode(var.private_subnets)
    private_vlans   = jsonencode(metal_vlan.private_vlans.*.vxlan)
    public_subnets  = jsonencode(var.public_subnets)
    public_vlans    = jsonencode(metal_vlan.public_vlans.*.vxlan)
    public_cidrs    = jsonencode(metal_reserved_ip_block.ip_blocks.*.cidr_notation)
    domain_name     = var.domain_name
  }
}

resource "metal_device" "router" {
  depends_on = [
    metal_ssh_key.ssh_pub_key
  ]
  hostname         = var.router_hostname
  plan             = var.router_size
  facilities       = [var.facility]
  operating_system = var.router_os
  billing_cycle    = var.billing_cycle
  project_id       = metal_project.new_project.id
  user_data        = data.template_file.user_data.rendered
}

resource "metal_device_network_type" "router" {
  device_id = metal_device.router.id
  type      = "hybrid"
}

resource "metal_port_vlan_attachment" "router_priv_vlan_attach" {
  depends_on = [metal_device_network_type.router]

  count     = length(metal_vlan.private_vlans)
  device_id = metal_device.router.id
  port_name = "eth1"
  vlan_vnid = element(metal_vlan.private_vlans.*.vxlan, count.index)
}

resource "metal_port_vlan_attachment" "router_pub_vlan_attach" {
  depends_on = [metal_device_network_type.router]

  count     = length(metal_vlan.public_vlans)
  device_id = metal_device.router.id
  port_name = "eth1"
  vlan_vnid = element(metal_vlan.public_vlans.*.vxlan, count.index)
}

resource "metal_ip_attachment" "block_assignment" {
  depends_on = [metal_device_network_type.router]

  count         = length(metal_reserved_ip_block.ip_blocks)
  device_id     = metal_device.router.id
  cidr_notation = element(metal_reserved_ip_block.ip_blocks.*.cidr_notation, count.index)
}
resource "metal_device" "esxi_hosts" {
  count            = var.esxi_host_count
  hostname         = format("%s%02d", var.esxi_hostname, count.index + 1)
  plan             = var.esxi_size
  facilities       = [var.facility]
  operating_system = var.vmware_os
  billing_cycle    = var.billing_cycle
  project_id       = metal_project.new_project.id
  ip_address {
    type            = "public_ipv4"
    cidr            = 29
    reservation_ids = [element(metal_reserved_ip_block.esx_ip_blocks.*.id, count.index)]
  }
  ip_address {
    type = "private_ipv4"
  }
  ip_address {
    type = "public_ipv6"
  }
}

resource "metal_device_network_type" "esxi_hosts" {
  count     = var.esxi_host_count
  device_id = metal_device.esxi_hosts[count.index].id
  type      = "hybrid"
}

resource "metal_port_vlan_attachment" "esxi_priv_vlan_attach" {
  depends_on = [metal_device_network_type.esxi_hosts]

  count     = length(metal_device.esxi_hosts) * length(metal_vlan.private_vlans)
  device_id = element(metal_device.esxi_hosts.*.id, ceil(count.index / length(metal_vlan.private_vlans)))
  port_name = "eth1"
  vlan_vnid = element(metal_vlan.private_vlans.*.vxlan, count.index)
}


resource "metal_port_vlan_attachment" "esxi_pub_vlan_attach" {
  depends_on = [metal_device_network_type.esxi_hosts]

  count     = length(metal_device.esxi_hosts) * length(metal_vlan.public_vlans)
  device_id = element(metal_device.esxi_hosts.*.id, ceil(count.index / length(metal_vlan.public_vlans)))
  port_name = "eth1"
  vlan_vnid = element(metal_vlan.public_vlans.*.vxlan, count.index)
}
data "template_file" "download_vcenter" {
  template = file("${path.module}/templates/download_vcenter.sh")
  vars = {
    s3_url           = var.s3_url
    s3_access_key    = var.s3_access_key
    s3_secret_key    = var.s3_secret_key
    s3_bucket_name   = var.s3_bucket_name
    vcenter_iso_name = var.vcenter_iso_name
  }
}

resource "null_resource" "download_vcenter_iso" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.router.access_public_ipv4
  }

  provisioner "file" {
    content     = data.template_file.download_vcenter.rendered
    destination = "/root/download_vcenter.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root",
      "chmod +x /root/download_vcenter.sh",
      "/root/download_vcenter.sh"
    ]
  }
}
resource "random_string" "ipsec_psk" {
  length           = 20
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "$!?@*"
}

resource "random_string" "vpn_pass" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "$!?@*"
}

data "template_file" "vpn_installer" {
  template = file("${path.module}/templates/l2tp_vpn.sh")
  vars = {
    ipsec_psk = random_string.ipsec_psk.result
    vpn_user  = var.vpn_user
    vpn_pass  = random_string.vpn_pass.result
  }
}

resource "null_resource" "install_vpn_server" {
  depends_on = [null_resource.download_vcenter_iso]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.router.access_public_ipv4
  }

  provisioner "file" {
    content     = data.template_file.vpn_installer.rendered
    destination = "/root/vpn_installer.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root",
      "chmod +x /root/vpn_installer.sh",
      "/root/vpn_installer.sh"
    ]
  }
}

resource "random_string" "vcenter_password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "$!?@*"
}

resource "random_string" "sso_password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  override_special = "$!?@*"
}

data "template_file" "vcva_template" {
  template = file("${path.module}/templates/vcva_template.json")
  vars = {
    vcenter_password = random_string.vcenter_password.result
    sso_password     = random_string.sso_password.result
    first_esx_pass   = metal_device.esxi_hosts.0.root_password
    domain_name      = var.domain_name
    vcenter_network  = var.vcenter_portgroup_name
    vcenter_domain   = var.vcenter_domain
  }
}

resource "null_resource" "copy_vcva_template" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.router.access_public_ipv4
  }
  provisioner "file" {
    content     = data.template_file.vcva_template.rendered
    destination = "/root/vcva_template.json"
  }
}
resource "null_resource" "copy_update_uplinks" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.router.access_public_ipv4
  }

  provisioner "file" {
    content     = file("${path.module}/templates/update_uplinks.py")
    destination = "/root/update_uplinks.py"
  }
}

data "template_file" "esx_host_networking" {
  template = file("${path.module}/templates/esx_host_networking.py")
  vars = {
    private_subnets = jsonencode(var.private_subnets)
    private_vlans   = jsonencode(metal_vlan.private_vlans.*.vxlan)
    public_subnets  = jsonencode(var.public_subnets)
    public_vlans    = jsonencode(metal_vlan.public_vlans.*.vxlan)
    public_cidrs    = jsonencode(metal_reserved_ip_block.ip_blocks.*.cidr_notation)
    domain_name     = var.domain_name
    metal_token     = var.auth_token
  }
}

resource "null_resource" "esx_network_prereqs" {
  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.router.access_public_ipv4
  }

  provisioner "file" {
    content     = data.template_file.esx_host_networking.rendered
    destination = "/root/esx_host_networking.py"
  }
}

resource "null_resource" "apply_esx_network_config" {
  count = length(metal_device.esxi_hosts)
  depends_on = [
    metal_port_vlan_attachment.esxi_priv_vlan_attach,
    metal_port_vlan_attachment.esxi_pub_vlan_attach,
    null_resource.esx_network_prereqs,
    null_resource.copy_update_uplinks
  ]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.router.access_public_ipv4
  }

  provisioner "remote-exec" {
    inline = ["python3 /root/esx_host_networking.py --host '${element(metal_device.esxi_hosts.*.access_public_ipv4, count.index)}' --user root --pass '${element(metal_device.esxi_hosts.*.root_password, count.index)}' --id '${element(metal_device.esxi_hosts.*.id, count.index)}' --index ${count.index} --ipRes ${element(metal_reserved_ip_block.esx_ip_blocks.*.id, count.index)}"]
  }
}
data "template_file" "deploy_vcva_script" {
  template = file("${path.module}/templates/deploy_vcva.py")
  vars = {
    private_subnets = jsonencode(var.private_subnets)
    public_subnets  = jsonencode(var.public_subnets)
    public_cidrs    = jsonencode(metal_reserved_ip_block.ip_blocks.*.cidr_notation)
    vcenter_network = var.vcenter_portgroup_name
    esx_passwords   = jsonencode(metal_device.esxi_hosts.*.root_password)
    dc_name         = var.vcenter_datacenter_name
    sso_password    = random_string.sso_password.result
    cluster_name    = var.vcenter_cluster_name
    vcenter_user    = var.vcenter_user_name
    vcenter_domain  = var.vcenter_domain
  }
}

data "template_file" "claim_vsan_disks" {
  template = file("${path.module}/templates/vsan_claim.py")
  vars = {
    vcenter_fqdn   = format("vcva.%s", var.domain_name)
    vcenter_user   = var.vcenter_user_name
    vcenter_domain = var.vcenter_domain
    vcenter_pass   = random_string.sso_password.result
    plan_type      = var.esxi_size
  }
}

resource "null_resource" "deploy_vcva" {
  depends_on = [null_resource.apply_esx_network_config]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
    host        = metal_device.router.access_public_ipv4
  }

  provisioner "file" {
    content     = data.template_file.claim_vsan_disks.rendered
    destination = "/root/vsan_claim.py"
  }

  provisioner "file" {
    content     = data.template_file.deploy_vcva_script.rendered
    destination = "/root/deploy_vcva.py"
  }

  provisioner "remote-exec" {
    inline = [
      "python3 /root/deploy_vcva.py",
      "sleep 60",
      "python3 /root/vsan_claim.py"
    ]
  }
}

