# Architecture

```text
Internet
   |
   | TCP 25565 (source configurable)
   v
Static Azure Public IP
   |
Network Security Group
   |
Network Interface
   |
Ubuntu 24.04 Azure VM
   |
Docker Compose
   |
Minecraft Java server container
   |
/opt/minecraft/data on the OS disk
```

Terraform creates one resource group, virtual network, subnet, static public IP,
network security group, network interface, and Linux VM. Cloud-init installs
Docker and starts the Minecraft Java server as a systemd-managed Compose
service.

## Security decisions

- Password authentication is disabled.
- Inbound SSH is disabled unless `ssh_source_address_prefix` is set.
- The Minecraft source range can be public (`*`) or limited to a CIDR.
- GitHub Actions validates Terraform but does not deploy or receive Azure
  credentials.

## Persistence and backups

World data lives at `/opt/minecraft/data` on the VM OS disk. Destroying the
Terraform stack destroys this data. Run `scripts/backup.sh` on the VM and copy
the resulting archive somewhere durable before destructive changes.

For a production or long-lived world, extend this project with a separate
managed data disk and an off-VM backup destination such as Azure Blob Storage.

