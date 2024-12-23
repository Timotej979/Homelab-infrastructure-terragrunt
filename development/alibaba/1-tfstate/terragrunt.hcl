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
        %{ if local.environment_vars.locals.alibaba_provider_config.enabled }
        resource "alicloud_oss_bucket" "tfstate_bucket" {
            bucket = "${local.environment}-tfstate"
            
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
            name = "${local.environment}-tfstate-lock"
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
    EOF
}