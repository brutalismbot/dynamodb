terraform {
  required_version = "~> 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.38"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags { tags = local.tags }

  endpoints { dynamodb = local.dynamodb_endpoint }
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
  hash_key       = "GUID"
  name           = "Brutalismbot"
  range_key      = "SORT"
  read_capacity  = 0
  write_capacity = 0

  attribute {
    name = "GUID"
    type = "S"
  }

  attribute {
    name = "SORT"
    type = "S"
  }

  attribute {
    name = "NAME"
    type = "S"
  }

  attribute {
    name = "KIND"
    type = "S"
  }

  attribute {
    name = "TEAM_ID"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  global_secondary_index {
    name            = "kind"
    hash_key        = "KIND"
    range_key       = "SORT"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "reddit-name"
    hash_key        = "NAME"
    range_key       = "GUID"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }

  global_secondary_index {
    name            = "slack-team"
    hash_key        = "TEAM_ID"
    projection_type = "ALL"
    read_capacity   = 0
    write_capacity  = 0
  }
}
