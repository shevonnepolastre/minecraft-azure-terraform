.PHONY: init fmt validate plan apply destroy

init:
	terraform init

fmt:
	terraform fmt -recursive

validate:
	terraform validate

plan:
	terraform plan -out=minecraft.tfplan

apply:
	terraform apply minecraft.tfplan

destroy:
	terraform plan -destroy -out=minecraft-destroy.tfplan
	terraform apply minecraft-destroy.tfplan

