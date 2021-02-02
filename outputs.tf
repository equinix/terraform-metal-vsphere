output "vpn_endpoint" {
  value       = metal_device.router.access_public_ipv4
  description = "L2TP VPN Endpoint"
}

output "vpn_psk" {
  value       = random_string.ipsec_psk.result
  description = "L2TP VPN Pre-Shared Key"
}

output "vpn_user" {
  value       = var.vpn_user
  description = "L2TP VPN username"
}

output "vpn_pasword" {
  value       = random_string.vpn_pass.result
  description = "L2TP VPN Password"
}

output "vcenter_fqdn" {
  value = format("vcva.%s", var.domain_name)
}

output "vcenter_username" {
  value = format("%s@%s", var.vcenter_user_name, var.vcenter_domain)
}

output "vcenter_password" {
  value = random_string.sso_password.result
}

output "vcenter_root_password" {
  value = random_string.vcenter_password.result
}

output "ssh_key_path" {
  value = "$HOME/.ssh/${local.ssh_key_name}"
}

output "bastion_host" {
  value = metal_device.router.access_public_ipv4
}

output "vcenter_ip" {
  value = lookup(data.external.get_vcenter_ip.result, "vcenter_ip")
}
