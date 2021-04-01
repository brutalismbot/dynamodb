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
  hash_key       = "KEY"
  name           = "Brutalismbot"
  range_key      = null
  read_capacity  = 0
  tags           = local.tags
  write_capacity = 0

  attribute {
    name = "KEY"
    type = "S"
  }

  attribute {
    name = "TYPE"
    type = "S"
  }

  attribute {
    name = "CREATED_UTC"
    type = "N"
  }

  attribute {
    name = "REDDIT_NAME"
    type = "S"
  }

  attribute {
    name = "SLACK_TEAM_ID"
    type = "S"
  }

  attribute {
    name = "SLACK_CHANNEL_ID"
    type = "S"
  }

  attribute {
    name = "TWITTER_APP_ID"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  global_secondary_index {
    name            = "REDDIT_POSTS"
    hash_key        = "REDDIT_NAME"
    range_key       = "CREATED_UTC"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "TYPES"
    hash_key        = "TYPE"
    range_key       = "KEY"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "SLACK_WEBHOOKS"
    hash_key        = "SLACK_TEAM_ID"
    range_key       = "SLACK_CHANNEL_ID"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "TWITTER_APPS"
    hash_key        = "TWITTER_APP_ID"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }
}
