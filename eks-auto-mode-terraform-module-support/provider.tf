terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.79"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.14.0"
    }
  }
}

