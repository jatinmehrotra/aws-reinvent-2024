# // This will be NOT deployed on EKS Auto Nodes

# resource "kubectl_manifest" "workload_not_on_eks_auto_node" {
#   yaml_body = <<YAML
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   labels:
#     environment: test
#   name: workload-not-on-eks-auto-nodes
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
#       affinity:
#         nodeAffinity:
#           requiredDuringSchedulingIgnoredDuringExecution:
#             nodeSelectorTerms:
#             - matchExpressions:
#               - key: eks.amazonaws.com/compute-type
#                 operator: NotIn
#                 values:
#                 - auto
#       containers:
#       - image: nginx:latest
#         name: nginx
# YAML
# }
