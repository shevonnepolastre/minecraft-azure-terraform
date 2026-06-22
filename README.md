# Minecraft Server on Azure with Terraform

This is a hands-on HashiCorp Terraform Associate study project. It was used to
build and troubleshoot a real Minecraft server on Azure, then tear it down
after determining that the Azure VM was more infrastructure and cost than the
server required.

The project demonstrates Terraform workflow, Azure networking, Linux virtual
machines, cloud-init, Docker, Fabric, state, partial applies, quota failures,
resource replacement, and destruction.

## What this creates

- Azure resource group
- Virtual network and subnet
- Static Standard public IP
- Network security group rules for Java Minecraft, Geyser/Bedrock, and optional
  restricted SSH
- Ubuntu Linux VM with SSH key authentication
- Docker-based Fabric Minecraft server configured by cloud-init
- Persistent server data under `/opt/minecraft/data`
- GitHub Actions workflow for `terraform fmt` and `terraform validate`

The VM uses Docker because the `itzg/minecraft-server` image automates Java,
Minecraft, Fabric, and mod installation. Docker is not required by Terraform;
it is the application deployment approach selected by this project.

## Prerequisites

- An Azure subscription
- Azure CLI
- Terraform 1.8 or newer
- An SSH key pair
- Sufficient Azure vCPU quota for the selected VM family and region
- The required Azure resource providers, including `Microsoft.Network` and
  `Microsoft.Compute`

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
   - Add the complete contents of an SSH `.pub` file, not its SHA256
     fingerprint or private key.
   - Review and accept the Minecraft EULA before setting `eula = true`.
   - Optionally set `ssh_source_address_prefix` to your public IP with `/32`.
   - Select a VM size whose family has quota in the chosen Azure region.
   - Set `minecraft_type = "FABRIC"` when using Fabric.
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
sudo cloud-init status --long
sudo docker ps
sudo docker logs -f minecraft
sudo ls -la /opt/minecraft/data
sudo ls -la /opt/minecraft/data/mods
```

The current cloud-init configuration starts the server with Docker Compose and
does not create a `minecraft.service` systemd unit. Manage it with:

```bash
cd /opt/minecraft
sudo docker compose stop
sudo docker compose start
sudo docker compose restart
```

The host directory `/opt/minecraft/data` is mounted into the container as
`/data`. Worlds and mods therefore persist outside the container.

## Fabric and Geyser

The container installs Fabric when its environment contains:

```yaml
TYPE: "FABRIC"
```

Fabric API can be downloaded from Modrinth with:

```yaml
MODRINTH_PROJECTS: "fabric-api"
```

Every Modrinth entry must be a valid project slug. An invalid slug causes the
container to restart repeatedly. Geyser additionally requires a compatible
Fabric mod and UDP port `19132` to be published by Docker and allowed by the
Azure network security group.

Opening a port does not install the software that listens on it.

## Problems encountered and lessons learned

### Mixed tutorial configurations

An unrelated Windows/IIS tutorial was initially mixed with the Linux
Minecraft configuration. This produced duplicate networks, public IPs, NICs,
NSGs, RDP rules, and a Windows VM in the plan.

`terraform validate` can succeed even when the proposed infrastructure is not
what was intended. Always inspect `terraform plan` for resource type, count,
ports, operating system, and destructive actions.

### Terraform resource labels

References must exactly match the resource's local label:

```hcl
resource "azurerm_resource_group" "this" {}
```

is referenced as:

```hcl
azurerm_resource_group.this.name
```

The label `this` exists only in Terraform. The Azure resource can still be
named `minecraft-rg`.

### Variables and values

- `variables.tf` declares input names, types, defaults, and validation.
- `terraform.tfvars` supplies deployment-specific values.
- `var.name` reads an input value.
- `.terraform.lock.hcl` records exact provider selections.
- `terraform.tfstate` records Terraform's managed-resource mappings.

Do not place real values in variable descriptions.

### Authentication and subscription context

`terraform validate` does not test Azure credentials. `terraform plan` and
`terraform apply` do. Azure CLI must be logged into the correct tenant and
subscription.

### Azure resource-provider registration

With:

```hcl
resource_provider_registrations = "none"
```

the required Azure providers must be registered manually. The first apply
partially succeeded by creating the resource group, then failed because
`Microsoft.Network` was not registered.

A partial apply is not automatically rolled back. Successfully created
resources are written to state and Terraform can continue after the cause is
fixed.

### VM-family quota

Total regional vCPU quota and VM-family quota are separate. Both the Bsv2 and
DSv5 attempts failed because their family limits were zero. A size from a
family with existing quota, `Standard_D2s_v3`, deployed successfully.

Check quota and SKU restrictions before deployment:

```bash
az vm list-usage --location eastus2 --output table
az vm list-skus --location eastus2 --size "<vm-size>" --all --output table
```

### SSH public keys

Azure requires the complete SSH public key, such as the one-line contents of:

```bash
cat ~/.ssh/id_ed25519.pub
```

The SHA256 fingerprint is not the public key. The private key must never be
placed in Terraform configuration or committed.

### Cloud-init and Docker Compose

Cloud-init is not required to create a VM. It was used here to install and
configure the application on first boot.

Two cloud-init failures occurred:

1. The incorrect Ubuntu package name `docker-compose-plugin` failed. Ubuntu
   24.04 provided `docker-compose-v2`.
2. Compose referenced the named volume `minecraft-data` without declaring it.
   The project was changed to the bind mount
   `/opt/minecraft/data:/data`.

Cloud-init normally runs on first boot. Correcting its template does not repair
an existing failed VM automatically. The VM was replaced deliberately:

```bash
terraform plan \
  -replace=azurerm_linux_virtual_machine.this \
  -out=tfplan
terraform apply tfplan
```

The static public IP and networking remained while only the VM was replaced.

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

After destruction, verify that Terraform manages nothing:

```bash
terraform state list
```

No output means the state is empty. The final documentation check showed an
empty Terraform state. Azure Portal and billing should still be checked
independently to confirm that no unmanaged or delayed-deletion resources
remain.

## Notes

- Java Edition uses TCP port `25565` by default.
- Geyser/Bedrock uses UDP port `19132`.
- Restrict SSH port `22` to a trusted public IP with a `/32` CIDR.
- The container image is `itzg/minecraft-server:latest`; pin it in
  `cloud-init/minecraft.yaml.tftpl` if you require supply-chain reproducibility.
- Pin the Minecraft version instead of using `LATEST` for repeatable rebuilds.
- Minecraft is a trademark of Microsoft. This project is not affiliated with
  or endorsed by Microsoft or Mojang.
