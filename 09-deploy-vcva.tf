data "template_file" "deploy_vcva_script" {
    template = file("templates/deploy_vcva.py")
    vars = {
        private_subnets = jsonencode(var.private_subnets)
        public_subnets = jsonencode(var.public_subnets)
        public_cidrs = jsonencode(packet_reserved_ip_block.ip_blocks.*.cidr_notation)
        vcenter_network = var.vcenter_portgroup_name
        esx_passwords = jsonencode(packet_device.esxi_hosts.*.root_password)
        dc_name = var.vcenter_datacenter_name
        sso_password = random_string.sso_password.result
        cluster_name = var.vcenter_cluster_name
        vcenter_user = var.vcenter_user_name
        vcenter_domain = var.vcenter_domain
    }
}

data "template_file" "claim_vsan_disks" {
    template = file("templates/vsan_claim.py")
    vars = {
        vcenter_fqdn = format("vcva.%s", var.domain_name)
        vcenter_user = var.vcenter_user_name
        vcenter_domain = var.vcenter_domain
        vcenter_pass = random_string.sso_password.result
        plan_type = var.esxi_size
    }
}

resource "null_resource" "deploy_vcva" {
    depends_on = [null_resource.apply_esx_network_config]
    connection {
        type = "ssh"
        user = "root"
        private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
        host = packet_device.router.access_public_ipv4
    }

    provisioner "file" {
        content = data.template_file.claim_vsan_disks.rendered
        destination = "/root/vsan_claim.py"
    }

    provisioner "file" {
        content = data.template_file.deploy_vcva_script.rendered
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

