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

generate "remote_state" {
    path      = "1-remote-state.tf"
    if_exists = "overwrite"
    contents  = <<EOF
        %{ if local.environment_vars.locals.aws_provider_config.enabled }
        resource "azurerm_resource_group" "tfstate_rg" {
            name     = "${local.environment}-tfstate-rg"
            location = ${local.environment_vars.locals.region}
        }
        %{ endif }
    EOF
}