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
        %{ if local.environment_vars.locals.alibaba_provider_config.enabled }
        terraform {
            required_providers {
                alicloud = {
                    source  = "aliyun/alicloud"
                    version = "${local.environment_vars.locals.alibaba_provider_config.version}"
                }
            }
        }

        provider "alicloud" {
            access_key = "${local.environment_vars.locals.alibaba_provider_config.access_key}"
            secret_key = "${local.environment_vars.locals.alibaba_provider_config.secret_key}"
            region     = "${local.environment_vars.locals.alibaba_provider_config.region}"
        }
        %{ endif }
    EOF
}