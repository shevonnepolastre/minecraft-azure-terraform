locals {
  resource_group_name = "${var.name_prefix}-rg"
  common_tags = merge(var.tags, {
    workload = "minecraft-server"
  })

  cloud_init = templatefile("${path.module}/cloud-init/minecraft.yaml.tftpl", {
    difficulty_json  = jsonencode(var.difficulty)
    eula_json        = jsonencode(var.eula ? "TRUE" : "FALSE")
    max_players_json = jsonencode(tostring(var.max_players))
    memory_json      = jsonencode(var.minecraft_memory)
    minecraft_port   = var.minecraft_port
    motd_json        = jsonencode(var.minecraft_motd)
    server_name_json = jsonencode(var.minecraft_server_name)
    version_json     = jsonencode(var.minecraft_version)
  })
}

