
# Create a Kubernetes rolebinding or clusterrolebinding that is bound to a Kubernetes role or clusterrole that has the necessary permissions to view the Kubernetes resources.
kubectl apply -f https://s3.us-west-2.amazonaws.com/amazon-eks/docs/eks-console-full-access.yaml

eksctl create iamidentitymapping \
    --cluster ${CLUSTER_NAME} \
    --region=${AWS_REGION} \
    --arn arn:aws:iam::767244377892:user/teja \
    --group eks-console-dashboard-full-access-group \
    --no-duplicate-arns
