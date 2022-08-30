#Install Kubecost

helm upgrade -i kubecost \
oci://public.ecr.aws/kubecost/cost-analyzer --version 1.96.0 \
--namespace kubecost --create-namespace \
-f https://raw.githubusercontent.com/kubecost/cost-analyzer-helm-chart/develop/cost-analyzer/values-eks-cost-monitoring.yaml --set service.type=LoadBalancer 