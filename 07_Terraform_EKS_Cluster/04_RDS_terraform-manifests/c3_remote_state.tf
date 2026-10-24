# Remote State Data Sources for VPC and EKS
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket"
    key    = "01_vpc/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket"
    key    = "02_eks/terraform.tfstate"
    region = var.aws_region
  }
}
