terraform {
  # 'backend-config' options must be passed like :
  # terraform init -input=false -backend=true \
  #   [with] -backend-config="backend.json"
  #     [or] -backend-config="backend.tfvars"
  #     [or] -backend-config="<key>=<value>"
  backend "s3" {}
}

provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}
