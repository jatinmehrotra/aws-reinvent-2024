resource "kubectl_manifest" "test_pdb" {
  yaml_body = <<YAML
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: test-pdb
  labels:
    environment: test
spec:
  minAvailable: 1
  selector:
    matchLabels:
      environment: test
YAML
}
