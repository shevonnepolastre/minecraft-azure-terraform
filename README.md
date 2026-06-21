# Minecraft Java Server on Azure with Terraform

A GitHub-ready Terraform project that deploys a Minecraft Java server on an
Ubuntu 24.04 Azure VM. The server runs in Docker, has a static public IP, and
stores world data under `/opt/minecraft/data`.

## What this creates

- Azure resource group
- Virtual network and subnet
- Static Standard public IP
- Network security group for Minecraft and optional SSH
- Ubuntu Linux VM with SSH key authentication
- Docker-based Minecraft Java server started by cloud-init
- GitHub Actions workflow for `terraform fmt` and `terraform validate`

## Prerequisites

- An Azure subscription
- Azure CLI
- Terraform 1.8 or newer
- An SSH key pair

## Deploy

1. Sign in to Azure:

   ```bash
   az login
   az account set --subscription "<subscription-id>"
   ```

2. Create your local variables file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars`:

   - Add your Azure subscription ID.
   - Add your SSH public key.
   - Review and accept the Minecraft EULA before setting `eula = true`.
   - Optionally set `ssh_source_address_prefix` to your public IP with `/32`.
   - Prefer a fixed `minecraft_version` instead of `LATEST` for repeatability.

4. Format, initialize, validate, and deploy:

   ```bash
   terraform fmt -recursive
   terraform init
   terraform validate
   terraform plan -out=minecraft.tfplan
   terraform apply minecraft.tfplan
   ```

5. Get the connection address:

   ```bash
   terraform output -raw minecraft_address
   ```

Cloud-init and the first Minecraft image download can take several minutes
after Terraform finishes.

## Administration

If you enabled SSH in `terraform.tfvars`:

```bash
ssh mcadmin@"$(terraform output -raw public_ip_address)"
```

On the VM:

```bash
sudo systemctl status minecraft
sudo docker logs -f minecraft
sudo docker exec -i minecraft rcon-cli
```

The helper scripts in `scripts/` can also be copied to or run on the VM.

## Remote Terraform state

Local state is suitable for initial testing but should never be committed.
For team use:

1. Create an Azure Storage account and private blob container for Terraform
   state.
2. Copy `backend.tf.example` to `backend.tf`.
3. Replace the placeholder values.
4. Run `terraform init -migrate-state`.

The real `backend.tf`, `terraform.tfvars`, state files, plans, and private keys
are ignored by Git.

## Costs and cleanup

Azure charges for the VM, managed OS disk, and public IPv4 address. Review the
Azure pricing for your selected region and VM size.

Back up the world before cleanup, then run:

```bash
terraform plan -destroy -out=minecraft-destroy.tfplan
terraform apply minecraft-destroy.tfplan
```

Destroying the stack permanently deletes the world stored on the VM disk.

## Notes

- This project deploys Minecraft Java Edition on TCP port 25565 by default.
- The container image is `itzg/minecraft-server:latest`; pin it in
  `cloud-init/minecraft.yaml.tftpl` if you require supply-chain reproducibility.
- Minecraft is a trademark of Microsoft. This project is not affiliated with
  or endorsed by Microsoft or Mojang.

