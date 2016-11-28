
all: apply


# If there is a terraform.tfvars
# use that as terraform input
# rather than depend on environment variables or user input
TF_VAR_ARGS ?=
TF_VAR_FILE ?= terraform.tfvars

ifdef TF_VAR_FILE
ifneq ($(wildcard $(TF_VAR_FILE)),)
TF_VAR_ARGS=--var-file=$(TF_VAR_FILE)
endif
endif

.PHONY: pause plan apply stop resume

TF_FILES=$(wildcard *.tf)

.terraform: $(TF_FILES)
	terraform get --update

plan: .terraform
	terraform plan -out terraform.tfplan $(TF_VAR_ARGS)

terraform.tfplan: $(TF_FILES) .terraform
	$(MAKE) plan

apply: terraform.tfplan
	terraform apply terraform.tfplan

clean: destroy
	#rm -rf .terraform
	#rm -rf terraform.tfstate
	rm -rf terraform.tfplan

destroy:
	terraform destroy $(TF_VAR_ARGS)

stop:
	aws ec2 stop-instances --instance-ids $(shell terraform output instance_id)

resume:
	aws ec2 start-instances --instance-ids $(shell terraform output instance_id)
