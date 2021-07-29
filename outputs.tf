output "vpn_endpoint" {
  value       = metal_device.router.access_public_ipv4
  description = "L2TP VPN Endpoint"
}

output "vpn_psk" {
  value       = random_password.ipsec_psk.result
  sensitive   = true
  description = "L2TP VPN Pre-Shared Key"
}

output "vpn_user" {
  value       = var.vpn_user
  description = "L2TP VPN username"
}

output "vpn_password" {
  value       = random_password.vpn_pass.result
  sensitive   = true
  description = "L2TP VPN Password"
}

output "vcenter_fqdn" {
  value       = format("vcva.%s", var.domain_name)
  description = "The FQDN of vCenter (Private DNS only)"
}

output "vcenter_username" {
  value       = format("%s@%s", var.vcenter_user_name, var.vcenter_domain)
  description = "The username to login to vCenter"
}

output "vcenter_password" {
  value       = random_password.sso_password.result
  sensitive   = true
  description = "The SSO Password to login to vCenter"
}

output "vcenter_root_password" {
  value       = random_password.vcenter_password.result
  sensitive   = true
  description = "The root password to ssh or login at the console of vCenter."
}

output "ssh_key_path" {
  value       = pathexpand("~/.ssh/${local.ssh_key_name}")
  description = "The path of to the private SSH key created for this deployment"
}

output "bastion_host" {
  value       = metal_device.router.access_public_ipv4
  description = "The ip of the basetion host that can run commands against all of the local IPs"
}

output "vcenter_ip" {
  value       = lookup(data.external.get_vcenter_ip.result, "vcenter_ip")
  description = "The IP address of vCenter"
}
