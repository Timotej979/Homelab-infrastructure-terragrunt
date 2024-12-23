locals {
    # Extract the environment variables from the env.hcl file
    environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

    # General high-level overview settings
    environment = local.environment_vars.locals.environment
    
    # Set the deployment name to the name of the directory
    deployment = basename(abspath(path_relative_to_include()))
}

inputs = {
    environment = local.environment
}

generate "provider" {
    path      = "0-provider.tf"
    if_exists = "overwrite"
    contents  = <<EOF
        %{ if local.environment_vars.locals.azure_provider_config.enabled }
        terraform {
            required_providers {
                azurerm = {
                    source  = "hashicorp/azurerm"
                    version = "${local.environment_vars.locals.aws_provider_config.version}"
                }
            }
        }

        provider "azurerm" {
            features = {}
        }
        %{ endif }
    EOF
}