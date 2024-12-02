provider "aws" {
  region = "us-east-1"
  # assume_role {
  #   role_arn     = "arn:aws:iam::xxxxx:role/xxxxxx"
  #   session_name = "jatin-eks-auto-mode-test"
  # }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
