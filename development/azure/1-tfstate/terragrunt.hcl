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

# Azure supports native state locking so no additional configuration is required
generate "remote_state" {
    path      = "1-remote-state.tf"
    if_exists = "overwrite"
    contents  = <<EOF
        %{ if local.environment_vars.locals.azure_provider_config.enabled }
        resource "azurerm_resource_group" "tfstate_rg" {
            name     = "${local.environment}-tfstate-rg"
            location = ${local.environment_vars.locals.azure_provider_config.region}
        }

        resource "azurerm_storage_account" "tfstate_sa" {
            name                      = "${local.environment}-tfstate-sa"
            resource_group_name       = azurerm_resource_group.tfstate_rg.name
            location                  = ${local.environment_vars.locals.azure_provider_config.region}
            account_tier              = "Standard"
            account_replication_type  = "LRS"
            enable_https_traffic_only = true
        }

        resource "azurerm_storage_container" "tfstate_container" {
            name                  = "${local.environment}-tfstate"
            storage_account_name = azurerm_storage_account.tfstate_sa.name
            container_access_type = "private"

            depends_on = [azurerm_storage_account.tfstate_sa]
        }
        %{ endif }
    EOF
}