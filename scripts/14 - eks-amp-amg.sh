# Install Prometheus

#Install Metrics Server 
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Prometheus/Grafana Stack 
helm repo add grafana-charts https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

eksctl create iamserviceaccount \
  --name amp-iamproxy-ingest-role \
  --namespace monitoring \
  --cluster "${CLUSTER_NAME}" \
  --attach-policy-arn arn:aws:iam::aws:policy/AmazonPrometheusRemoteWriteAccess \
  --approve \
  --override-existing-serviceaccounts

curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/prometheus-values.yaml | tee prometheus-values.yaml

helm install --namespace monitoring prometheus prometheus-community/prometheus --values prometheus-values.yaml --set serviceAccounts.server.name="amp-iamproxy-ingest-role" --set serviceAccounts.server.create="false" --set serviceAccounts.alertmanager.create="false" --set serviceAccounts.pushgateway.create="false" --set server.remoteWrite[0].url="https://aps-workspaces.${AWS_REGION}.amazonaws.com/workspaces/${WORKSPACE_ID}/api/v1/remote_write" --set server.remoteWrite[0].sigv4.region=${AWS_REGION}

#curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/grafana-values.yaml | tee grafana-values.yaml
#helm install --namespace monitoring grafana grafana-charts/grafana --values grafana-values.yaml --set service.type=LoadBalancer --set adminPassword='Test123'