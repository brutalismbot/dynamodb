terraform {
  required_version = "~> 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  endpoints {
    dynamodb = local.dynamodb_endpoint
  }
}

locals {
  dynamodb_endpoint = terraform.workspace == "local" ? "http://localhost:8000/" : null

  tags = terraform.workspace == "local" ? {} : {
    App  = "Brutalismbot"
    Repo = "https://github.com/brutalismbot/dynamodb"
  }
}

resource "aws_dynamodb_table" "brutalismbot" {
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "HASH"
  name           = "Brutalismbot"
  range_key      = "SORT"
  read_capacity  = 0
  tags           = local.tags
  write_capacity = 0

  attribute {
    name = "HASH"
    type = "S"
  }

  attribute {
    name = "SORT"
    type = "S"
  }

  attribute {
    name = "REDDIT_NAME"
    type = "S"
  }

  attribute {
    name = "SLACK_WEBHOOK_KEY"
    type = "S"
  }

  attribute {
    name = "TWITTER_HANDLE"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  global_secondary_index {
    name            = "SORT"
    hash_key        = "SORT"
    range_key       = "HASH"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "REDDIT_NAME"
    hash_key        = "REDDIT_NAME"
    range_key       = "HASH"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "TWITTER_HANDLE"
    hash_key        = "TWITTER_HANDLE"
    range_key       = "HASH"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "SLACK_WEBHOOK_KEY"
    hash_key        = "SLACK_WEBHOOK_KEY"
    range_key       = "HASH"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }
}
