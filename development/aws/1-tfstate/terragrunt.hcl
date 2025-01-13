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

# AWS partially supports state locking so S3 bucket and DynamoDB table are required
generate "remote_state" {
    path      = "1-remote-state.tf"
    if_exists = "overwrite"
    contents  = <<EOF
        %{ if local.environment_vars.locals.aws_provider_config.enabled }
        # Create the KMS key
        resource "aws_kms_key" "${local.environment}_tfstate_kms_key" {
            description             = "This key is used to encrypt the Terraform state bucket"
            deletion_window_in_days = 10
            enable_key_rotation     = true
            }

            resource "aws_kms_alias" "${local.environment}_tfstate_kms_alias" {
            name          = "tfstate/${local.environment}"
            target_key_id = aws_kms_key.${local.environment}_tfstate_kms_key.key_id
            }

        # Create the S3 bucket with versioning and encryption
        resource "aws_s3_bucket" "${local.environment}_tfstate_bucket" {
            bucket = "${local.environment}-tfstate"
            acl    = "private"

            versioning {
                enabled = true
            }

            server_side_encryption_configuration {
                rule {
                    apply_server_side_encryption_by_default {
                        sse_algorithm = "aws:kms"
                        kms_master_key_id = aws_kms_key.${local.environment}_tfstate_kms_key.key_id
                    }
                }
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
        resource "aws_s3_bucket_public_access_block" "${local.environment}_tfstate_bucket_acl" {
            bucket = aws_s3_bucket.${local.environment}_tfstate_bucket.bucket
            block_public_acls       = true
            block_public_policy     = true
            ignore_public_acls      = true
            restrict_public_buckets = true
        }

        # Create the DynamoDB table for state locking
        resource "aws_dynamodb_table" "tfstate_lock"
            name           = "${local.environment}-tfstate-lock"
            read_capacity  = 20
            write_capacity = 20
            hash_key       = "LockID"

            attribute {
                name = "LockID"
                type = "S"
            }

            lifecycle {
                prevent_destroy = false
            }

            tags = {
                Environment = "${local.environment}"
                Deployment  = "${local.deployment}"
            }
        }
        %{ endif }
    EOF
}