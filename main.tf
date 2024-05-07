provider "aws" {
    region = "eu-west-2"
  
}

//create an s3 bucket
resource "aws_s3_bucket" "terraform_state_test" {
    bucket = "terraform-up-and-running-state-affaxerd"
    
    #prevent accidental deletion of this s3 bucket

    lifecycle {
      prevent_destroy = true

    }
      
      
}

//bucket versioning
resource "aws_s3_bucket_versioning" "enabled" {

  
    bucket = aws_s3_bucket.terraform_state_test.id
  
    versioning_configuration{
        status = "Enabled"
    }     
}

//enable automatic serverside encryption to any data on the bucker
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state_test.id

    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  
}

//Explicitly block all public access to s3
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket = aws_s3_bucket.terraform_state_test.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
  
}

//create a dynamo db for locking
resource "aws_dynamodb_table" "terraform_locks" {
    name = "terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
      name = "LockID"
      type = "S"
    }
  
}

//state is currently stored locally, so to store state in S3, add backend configuration
terraform {
    backend "s3" {
        bucket = "terraform-up-and-running-state-affaxerd"
        key= "global/s3/terraform.tfstate"
        region = "eu-west-2"

        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
  
}

//testing...
output "s3_bucket_arn" {
    value = aws_s3_bucket.terraform_state_test.arn
    description = "The ARN of the S3 bucket"
  
}

output "dynamo_db_table_name" {
    value = aws_dynamodb_table.terraform_locks.name
    description = "The name of the DynamoDB table"
  
}