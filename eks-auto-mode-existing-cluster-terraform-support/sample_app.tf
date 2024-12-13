resource "kubectl_manifest" "test" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    environment: test
  name: test
spec:
  replicas: 2
  selector:
    matchLabels:
      environment: test
  template:
    metadata:
      labels:
        environment: test
    spec:
      containers:
      - image: nginx:1.16
        name: nginx
YAML
}


