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
        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "oss" }
        terraform {
            required_providers {
                alicloud = {
                    source  = "aliyun/alicloud"
                    version = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.version}"
                }
            }
        }

        provider "alicloud" {
            access_key = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.access_key}"
            secret_key = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.secret_key}"
            region     = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.region}"
        }
        %{ endif }

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "cos" }
        terraform {
            required_providers {
                tencentcloud = {
                    source  = "tencentcloudstack/tencentcloud"
                    version = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.version}"
                }
            }
        }

        provider "tencentcloud" {
            secret_id = ${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.secret_id}
            secret_key = ${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.secret_key}
            region = ${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.region}
        }
        %{ endif }

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "s3" }
        terraform {
            required_providers {
                aws = {
                    source  = "hashicorp/aws"
                    version = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.version}"
                }
            }
        }

        provider "aws" {
            profile = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.profile}"
            region  = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.region}"
            allowed_account_ids = ["${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.allowed_account_id}"]
            default_tags = {
                tags = {
                    Environment = "${local.environment}"
                    Deployment  = "${local.deployment}"
                }
            }
        }
        %{ endif }

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "azurerm" }
        terraform {
            required_providers {
                azurerm = {
                    source  = "hashicorp/azurerm"
                    version = "${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.version}"
                }
            }
        }

        provider "azurerm" {
            features = {}
        }
        %{ endif }

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "gcs" }
        terraform {
            required_providers {
                google = {
                    source  = "hashicorp/google"
                    version = ${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.version}
                }
            }
        }

        provider "google" {
            credentials = file("${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.credentials_file}")
            project     = ${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.project}
            region      = ${local.environment_vars.locals.baremetal_provider_config.backend_config.credentials.region}
        }
        %{ endif }
    EOF
}