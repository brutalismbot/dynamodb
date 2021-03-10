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
  billing_mode   = "PROVISIONED"
  hash_key       = "HASH"
  name           = "Brutalismbot"
  range_key      = "SORT"
  read_capacity  = 1
  tags           = local.tags
  write_capacity = 1

  attribute {
    name = "HASH"
    type = "S"
  }

  attribute {
    name = "SORT"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  global_secondary_index {
    name            = "LIST"
    hash_key        = "SORT"
    range_key       = "HASH"
    write_capacity  = 1
    read_capacity   = 1
    projection_type = "ALL"
  }
}
