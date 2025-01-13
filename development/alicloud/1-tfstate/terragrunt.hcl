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

# alicloud does not support native state locking so we need to create an OSS bucket and OTS table
generate "remote_state" {
    path      = "1-remote-state.tf"
    if_exists = "overwrite"
    contents  = <<EOF
        %{ if local.environment_vars.locals.alicloud_provider_config.enabled }
        # Create a KMS key
        resource "alicloud_kms_key" "${local.environment}_tfstate_kms_key" {
            description = "KMS key for encrypting Terraform state bucket"
            key_usage   = "ENCRYPT/DECRYPT"
            deletion_protection = false

            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }

        # Create the OSS bucket with KMS encryption and versioning
        resource "alicloud_oss_bucket" "${local.environment}_tfstate_bucket" {
            bucket = "${local.environment}-tfstate"

            versioning {
                status = "Enabled"
            }

            server_side_encryption_rule {
                sse_algorithm     = "KMS"
                kms_master_key_id = alicloud_kms_key.${local.environment}_tfstate_kms_key.key_id
            }

            lifecycle {
                prevent_destroy = false
            }

            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }

        # Set the ACL on the bucket to private
        resource "alicloud_oss_bucket_acl" "${local.environment}_tfstate_bucket_acl" {
            bucket = alicloud_oss_bucket.${local.environment}_tfstate_bucket.bucket
            acl    = "private"

            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }

        # Create the OTS instance for state locking
        resource "alicloud_ots_instance" "${local.environment}_tfstate_lock_instance" {
            name          = "${local.environment}-tfstate-lock"
            instance_type = "HighIO"
            description   = "Terraform state lock"
            accessed_by   = "Any"

            lifecycle {
                prevent_destroy = false
            }

            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }

        # Create the OTS table for state locking
        resource "alicloud_ots_table" "${local.environment}_tfstate_lock_table" {
            instance_name = alicloud_ots_instance.${local.environment}_tfstate_lock_instance.instance_name
            max_version   = 1
            table_name    = "Locks"
            time_to_live  = -1

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