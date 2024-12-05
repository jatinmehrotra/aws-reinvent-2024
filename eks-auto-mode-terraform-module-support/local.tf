locals {
  cluster_name = "tf-module-support"
}

# locals {
#   fluent_bit_irsa_name = "fluent_bit_irsa"
#   fluent_bit_sa_name   = "eks-aws-for-fluent-bit"
# }

# locals {
#   metrics_namespace = "prometheus"
# }

# locals {
#   alb_ingress_controller_irsa_name = "alb_ingress_ctrl_irsa"
#   alb_ingress_controller_sa_name   = "eks-aws-for-alb-ingress-sa"
# }

locals {
  node_group_desired_size = 2
}
