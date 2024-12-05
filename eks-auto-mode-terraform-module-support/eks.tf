module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name                   = local.cluster_name
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true


  vpc_id = module.vpc.vpc_id
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }
  subnet_ids = module.vpc.private_subnets



  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true


  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
