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
        resource "aws_s3_bucket" "tfstate_bucket" {
            bucket = "${local.environment}-tfstate"
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
            name           = "${local.environment}-tfstate-lock"
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
    EOF
}