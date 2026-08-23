terraform {
  required_version = ">= 1.5"

  required_providers {
    notion = {
      source  = "delize/notion"
      version = "~> 0.9"
    }
  }
}

# Token comes from the NOTION_TOKEN environment variable (provider default) —
# see README.md. Do not put the token in a .tf or .tfvars file.
provider "notion" {}
