variable "subscription_id" {
  description = "Azure subscription ID used for this deployment."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Azure region in which resources are created."
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Short lowercase prefix used in Azure resource names."
  type        = string
  default     = "minecraft"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,19}$", var.name_prefix))
    error_message = "name_prefix must be 2-20 lowercase letters, numbers, or hyphens and start with a letter."
  }
}

variable "vm_size" {
  description = "Azure VM size. Standard_D2s_v5 is a reasonable starting point for a small server."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "Linux administrator username."
  type        = string
  default     = "mcadmin"
}

variable "ssh_public_key" {
  description = "OpenSSH public key for VM administration."
  type        = string
  sensitive   = true
}

variable "ssh_source_address_prefix" {
  description = "CIDR allowed to connect over SSH, such as 203.0.113.10/32. Set to null to disable inbound SSH."
  type        = string
  default     = null
  nullable    = true
}

variable "minecraft_source_address_prefix" {
  description = "CIDR allowed to connect to Minecraft. Use * for a public server."
  type        = string
  default     = "*"
}

variable "minecraft_port" {
  description = "Public and container port for the Minecraft Java server."
  type        = number
  default     = 25565

  validation {
    condition     = var.minecraft_port >= 1024 && var.minecraft_port <= 65535
    error_message = "minecraft_port must be between 1024 and 65535."
  }
}

variable "minecraft_version" {
  description = "Minecraft version passed to the container. Use a specific version for reproducible deployments."
  type        = string
  default     = "LATEST"
}

variable "minecraft_server_name" {
  description = "Server name exposed to the Minecraft container."
  type        = string
  default     = "Azure Minecraft Server"
}

variable "minecraft_motd" {
  description = "Message shown in the Minecraft multiplayer server list."
  type        = string
  default     = "A Minecraft server running on Azure"
}

variable "minecraft_memory" {
  description = "Java heap allocation passed to the Minecraft container, for example 2G or 4G."
  type        = string
  default     = "2G"

  validation {
    condition     = can(regex("^[1-9][0-9]*[MG]$", var.minecraft_memory))
    error_message = "minecraft_memory must be a whole number followed by M or G, such as 2048M or 2G."
  }
}

variable "max_players" {
  description = "Maximum number of simultaneous players."
  type        = number
  default     = 10

  validation {
    condition     = var.max_players >= 1 && var.max_players <= 1000
    error_message = "max_players must be between 1 and 1000."
  }
}

variable "difficulty" {
  description = "Minecraft difficulty: peaceful, easy, normal, or hard."
  type        = string
  default     = "normal"

  validation {
    condition     = contains(["peaceful", "easy", "normal", "hard"], var.difficulty)
    error_message = "difficulty must be peaceful, easy, normal, or hard."
  }
}

variable "eula" {
  description = "You must accept the Minecraft EULA before deployment."
  type        = bool
  default     = false

  validation {
    condition     = var.eula
    error_message = "Set eula = true only after reviewing and accepting https://aka.ms/MinecraftEULA."
  }
}

variable "os_disk_size_gb" {
  description = "OS disk size. Minecraft world data is stored under /opt/minecraft/data on this disk."
  type        = number
  default     = 64
}

variable "tags" {
  description = "Additional tags applied to Azure resources."
  type        = map(string)
  default = {
    application = "minecraft"
    managed-by  = "terraform"
  }
}

