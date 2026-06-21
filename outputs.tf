output "minecraft_address" {
  description = "Address players use to connect."
  value       = "${azurerm_public_ip.this.ip_address}:${var.minecraft_port}"
}

output "public_ip_address" {
  description = "Static public IP address of the server."
  value       = azurerm_public_ip.this.ip_address
}

output "resource_group_name" {
  description = "Azure resource group containing the server."
  value       = azurerm_resource_group.this.name
}

output "ssh_command" {
  description = "SSH command, when inbound SSH has been enabled."
  value       = var.ssh_source_address_prefix == null ? "SSH is disabled by the NSG" : "ssh ${var.admin_username}@${azurerm_public_ip.this.ip_address}"
}

