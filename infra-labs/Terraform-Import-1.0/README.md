# Terraform Import

## Purpose

This folder shows how to import existing AWS resources into Terraform state and manage them with Terraform configuration.

## What this example includes

- `main.tf` — Terraform resource configuration 
- `README.md` — process documentation

## Import workflow

1. Define the resource block in `main.tf` for the existing AWS resource.
2. Run `terraform init` to initialize the working directory.
3. Run `terraform import <RESOURCE_ADDRESS> <RESOURCE_ID>` to import the resource into state.
4. Run `terraform plan` and adjust the configuration until the plan shows no changes.
5. Apply only after the imported resource and configuration are aligned.

## Example commands

```bash
terraform init
terraform import aws_instance.example i-0123456789abcdef0
terraform plan
```

## Key points

- `terraform import` adds an existing resource to Terraform state only.
- It does not create or modify `.tf` configuration automatically.
- After import, the Terraform resource block must match the actual remote resource attributes.
- Use `terraform plan` to identify any configuration drift.

## Best practices

- Keep imported configurations minimal and expand them incrementally.
- Use `terraform state list` to confirm imported resources are tracked.
- Do not commit `.terraform/`, `terraform.tfstate`, or `terraform.tfstate.backup` to source control.
- Document the imported resource ID and the original resource source.

## Result

After a successful import, Terraform can manage the existing AWS resource without recreating it.

This makes it possible to bring existing infrastructure under Terraform control safely.




