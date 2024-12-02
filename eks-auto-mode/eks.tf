module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = local.cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true


  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_enabled_log_types = [
    "audit",
    "api",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  cluster_addons = {
    coredns = {}
    # eks-pod-identity-agent = {}
    kube-proxy = {}
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true


  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["m5.large"]
    # instance_types = ["t3.small"]
    # vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
    iam_role_additional_policies = {
      ebs_policy                                 = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" #IAM rights needed by CSI driver
      auto_scaling_policy                        = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
      cloudwatch_container_insights_agent_policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      xray_policy                                = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
    }
  }

  eks_managed_node_groups = {

    node_group = {
      min_size     = 2
      max_size     = 5
      desired_size = local.node_group_desired_size
    }
  }

  node_security_group_additional_rules = {
    http_traffic_node_to_node = {
      description = "Allow inbound HTTP from self"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      self        = true
      type        = "ingress"
    }
  }



  fargate_profile_defaults = {
    iam_role_additional_policies = {
      ebs_policy                                 = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" #IAM rights needed by CSI driver
      auto_scaling_policy                        = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
      cloudwatch_container_insights_agent_policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      xray_policy                                = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
    }
  }

  fargate_profiles = {
    deployment = {
      name = "example"
      selectors = [
        {
          namespace = "fargate-test"
        }
      ]

      # # Using specific subnets instead of the subnets supplied for the cluster itself
      # subnet_ids = [module.vpc.private_subnets[1]]

      tags = {
        Owner = "secondary"
      }
    }
    # kube-system = {
    #   selectors = [
    #     { namespace = "kube-system" }
    #   ]
    # }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "null_resource" "update_desired_size" {
  triggers = {
    desired_size = local.node_group_desired_size
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      aws eks update-nodegroup-config \
        --cluster-name ${module.eks.cluster_name} \
        --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["node_group"].node_group_id), 1)} \
        --scaling-config desiredSize=${local.node_group_desired_size} \
        --region us-east-1 \
        --profile ck-test
    EOT
  }
}
