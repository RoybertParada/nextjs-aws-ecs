include {
    path = find_in_parent_folders()
}

locals {
  # Automatically load account-level variables
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  # Automatically load environment-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_account_id = local.account_vars.locals.aws_account_id
  # Extract out common variables for reuse
  aws_region = local.region_vars.locals.aws_region
}

terraform {
    source = "git@github.com:terraform-aws-modules/terraform-aws-vpc?ref=v5.8.1"
}

inputs = {
    name = "poc-vpc"
    cidr = "10.0.0.0/16"

    azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    enable_dns_support   = true
    enable_dns_hostnames = true
    enable_nat_gateway = true
    single_nat_gateway = true
    tags = {
        Environment = "poc"
        Terraform   = "true"
    }
}
