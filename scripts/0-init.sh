export CLUSTER_NAME="eks-emr-cluster"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export AWS_REGION="us-east-2" 
export WORKSPACE_ID=$(aws amp list-workspaces --alias eks-emr-workspace | jq .workspaces[0].workspaceId -r)