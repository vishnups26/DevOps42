terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # NOTE: This backend block is intentionally left partial (no values).
  # Values are supplied at `terraform init` time via `-backend-config`
  # arguments (see deploy/templates/terraform-template.yml). This lets the
  # same Terraform code be reused for every environment (env01, env02, ...)
  # without hardcoding a single storage account/key here.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}
