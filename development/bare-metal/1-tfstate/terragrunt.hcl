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
       %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "oss" }
       resource "alicloud_oss_bucket" "tfstate_bucket" {
            bucket = "${local.environment}-tfstate-baremetal"
            
            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }

        resource "alicloud_oss_bucket_acl" "tfstate_bucket_acl" {
            bucket = alicloud_oss_bucket.tfstate_bucket.bucket
            acl    = "private"
        }

        resource "alicloud_ots_instance" "tfstate_lock" {
            name = "${local.environment}-tfstate-lock-baremetal"
            instance_type = "HighIO"
            description = "Terraform state lock"
            accessed_by = "Any"
            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }

        resource "alicloud_ots_table" "tfstate_lock_table" {
            instance_name = alicloud_ots_instance.tfstate_lock.name
            max_version = 1
            table_name = "Locks"
            time_to_live = -1
            primary_key = {
                name = "LockID"
                type = "STRING"
            }
            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }
        %{ endif }

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "cos" }
        resource "tencentcloud_cos_bucket" "tfstate_bucket" {
            bucket = "${local.environment}-tfstate-baremetal"
            acl    = "private"
            
            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }
        %{ endif }

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "s3" }
        resource "aws_s3_bucket" "tfstate_bucket" {
            bucket = "${local.environment}-tfstate-baremetal"
            acl    = "private"

            lifecycle {
                prevent_destroy = false
            }

            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }

        resource "aws_dynamodb_table" "tfstate_lock"
            name           = "${local.environment}-tfstate-lock-baremetal"
            read_capacity  = 20
            write_capacity = 20
            hash_key       = "LockID"
            attribute {
                name = "LockID"
                type = "S"
            }

            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }
        %{ endif }

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "azurerm" }
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

        %{ if local.environment_vars.locals.baremetal_provider_config.backend_config.type == "gcs" }
        resource "google_storage_bucket" "tfstate_bucket" {
            name     = "${local.environment}-tfstate"
            location = "${local.environment_vars.locals.gcp_provider_config.region}"
            storage_class = "REGIONAL"
        } 
        %{ endif }
    EOF
}