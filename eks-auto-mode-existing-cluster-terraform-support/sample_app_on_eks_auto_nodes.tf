# // This will be deployed on EKS Auto Nodes
# resource "kubectl_manifest" "workload_on_eks_auto_nodes" {
#   yaml_body = <<YAML
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   labels:
#     environment: test
#   name: workload-on-eks-auto-nodes
# spec:
#   replicas: 2
#   selector:
#     matchLabels:
#       environment: test
#   template:
#     metadata:
#       labels:
#         environment: test
#     spec:
#       nodeSelector:
#         eks.amazonaws.com/compute-type: auto
#       containers:
#       - image: httpd:alpine3.21
#         name: apache
# YAML
# }
