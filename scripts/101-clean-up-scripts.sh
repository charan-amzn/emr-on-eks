
eksctl delete iamidentitymapping \
    --cluster ${CLUSTER_NAME} \
    --region=${AWS_REGION} \
    --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${MY_EKSCONSOLE_ROLE} \

kubectl delete -f https://s3.us-west-2.amazonaws.com/amazon-eks/docs/eks-console-full-access.yaml


# unInstall karpenter
helm uninstall --namespace karpenter karpenter
helm uninstall --namespace monitoring prometheus
helm uninstall --namespace monitoring grafana 
helm uninstall kubecost --namespace kubecost 
aws iam delete-role --role-name "${CLUSTER_NAME}-karpenter"
aws cloudformation delete-stack --stack-name "Karpenter-${CLUSTER_NAME}"


# Clean up S3 Folder for Demo JObs Templates.
export DEMO_JOBS_PATH=s3://${CLUSTER_NAME}-demojobs-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 rm $DEMO_JOBS_PATH  --recursive
aws s3 rb $DEMO_JOBS_PATH --force



# Clean up S3 Folder for Pod Templates.
export POD_TEMPLATE_PATH=s3://${CLUSTER_NAME}-pod-templates-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 rm $POD_TEMPLATE_PATH  --recursive
aws s3 rb $POD_TEMPLATE_PATH --force
export POD_TEMPLATE_PATH=s3://${CLUSTER_NAME}-pod-templates-new-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 rm $POD_TEMPLATE_PATH  --recursive
aws s3 rb $POD_TEMPLATE_PATH --force




# Delete CloudWatch logs location
aws logs delete-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/realtime-submission
aws logs delete-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/intra-day-submission
aws logs delete-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/nightly-submission
aws logs delete-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/monthly-submission
aws logs delete-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/adhoc-ml-submission

# Delete logs from S3 bucket
aws s3 rm s3://realtime-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --recursive
aws s3 rm s3://intra-day-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --recursive
aws s3 rm s3://nightly-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --recursive
aws s3 rm s3://monthly-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --recursive
aws s3 rm s3://adhoc-ml-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --recursive

# Delete S3 bucket
aws s3 rb s3://realtime-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --force
aws s3 rb s3://intra-day-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --force
aws s3 rb s3://nightly-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --force
aws s3 rb s3://monthly-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --force
aws s3 rb s3://adhoc-ml-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION} --force


# Deleting job execution roles and policies
aws iam delete-role-policy --role-name realtime-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution
aws iam delete-role --role-name realtime-submission-JobExecutionRole 

aws iam delete-role-policy --role-name intra-day-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution
aws iam delete-role --role-name intra-day-submission-JobExecutionRole

aws iam delete-role-policy --role-name nightly-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution
aws iam delete-role --role-name nightly-submission-JobExecutionRole

aws iam delete-role-policy --role-name monthly-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution
aws iam delete-role --role-name monthly-submission-JobExecutionRole

aws iam delete-role-policy --role-name adhoc-ml-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution
aws iam delete-role --role-name adhoc-ml-submission-JobExecutionRole


# Deleting EMR virtual clusters
aws emr-containers delete-virtual-cluster \
--id $(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='realtime-submission-emr-cluster' && state=='RUNNING' && containerProvider.id=='${CLUSTER_NAME}'].id" --output text) \
--no-cli-pager

aws emr-containers delete-virtual-cluster \
--id $(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='intra-day-submission-emr-cluster' && state=='RUNNING' && containerProvider.id=='${CLUSTER_NAME}'].id" --output text) \
--no-cli-pager

aws emr-containers delete-virtual-cluster \
--id $(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='nightly-submission-emr-cluster' && state=='RUNNING' && containerProvider.id=='${CLUSTER_NAME}'].id" --output text) \
--no-cli-pager

aws emr-containers delete-virtual-cluster \
--id $(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='monthly-submission-emr-cluster' && state=='RUNNING' && containerProvider.id=='${CLUSTER_NAME}'].id" --output text) \
--no-cli-pager

aws emr-containers delete-virtual-cluster \
--id $(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='adhoc-ml-submission-emr-cluster' && state=='RUNNING' && containerProvider.id=='${CLUSTER_NAME}'].id" --output text) \
--no-cli-pager

# Deleting EKS namesapces 
# * Deletes roles and rolebinding along with it
kubectl delete namespace realtime-submission
kubectl delete namespace intra-day-submission
kubectl delete namespace nightly-submission
kubectl delete namespace monthly-submission
kubectl delete namespace adhoc-ml-submission

# Detaching CloudWatchAgentServerPolicy from 
STACK_NAME=$(eksctl get nodegroup --cluster ${CLUSTER_NAME} -o json | jq -r '.[].StackName')
ROLE_NAME=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME | jq -r '.StackResources[] | select(.ResourceType=="AWS::IAM::Role") | .PhysicalResourceId')
aws iam detach-role-policy --role-name ${ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

# Deleting Instance Role 
INSTANCE_PROFILE=$(aws iam list-instance-profiles-for-role --role-name $ROLE_NAME | jq -r '.InstanceProfiles[].InstanceProfileName')

aws iam remove-role-from-instance-profile --instance-profile-name $INSTANCE_PROFILE --role-name $ROLE_NAME
aws iam delete-instance-profile --instance-profile-name $INSTANCE_PROFILE

aws iam delete-role --role-name ${ROLE_NAME}


#Deleting the Cluster
eksctl delete cluster --name=${CLUSTER_NAME}




