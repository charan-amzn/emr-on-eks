

#Create IAM Role for job execution

#Trust Policy for EMR
cat <<EoF > emr-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EoF
# Creating Role with Trust Policy
aws iam create-role --role-name realtime-submission-JobExecutionRole --assume-role-policy-document file://emr-trust-policy.json --no-cli-pager
aws iam create-role --role-name intra-day-submission-JobExecutionRole --assume-role-policy-document file://emr-trust-policy.json --no-cli-pager
aws iam create-role --role-name nightly-submission-JobExecutionRole --assume-role-policy-document file://emr-trust-policy.json --no-cli-pager
aws iam create-role --role-name monthly-submission-JobExecutionRole --assume-role-policy-document file://emr-trust-policy.json --no-cli-pager
aws iam create-role --role-name adhoc-ml-submission-JobExecutionRole --assume-role-policy-document file://emr-trust-policy.json --no-cli-pager

# Policy For s3 & Cloud Watch
cat <<EoF > EMRContainers-JobExecutionRole.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
}  
EoF

# Attach log policy to Execution Roles
aws iam put-role-policy --role-name realtime-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution --policy-document file://EMRContainers-JobExecutionRole.json
aws iam put-role-policy --role-name intra-day-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution --policy-document file://EMRContainers-JobExecutionRole.json
aws iam put-role-policy --role-name nightly-submission-JobExecutionRole  --policy-name EMR-Containers-Job-Execution --policy-document file://EMRContainers-JobExecutionRole.json
aws iam put-role-policy --role-name monthly-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution --policy-document file://EMRContainers-JobExecutionRole.json
aws iam put-role-policy --role-name adhoc-ml-submission-JobExecutionRole --policy-name EMR-Containers-Job-Execution --policy-document file://EMRContainers-JobExecutionRole.json

# Update trust relationship for job execution role - (Between IAM Roles & EMR Service Identity)
aws emr-containers update-role-trust-policy --cluster-name ${CLUSTER_NAME} --namespace realtime-submission --role-name realtime-submission-JobExecutionRole
aws emr-containers update-role-trust-policy --cluster-name ${CLUSTER_NAME} --namespace intra-day-submission --role-name intra-day-submission-JobExecutionRole
aws emr-containers update-role-trust-policy --cluster-name ${CLUSTER_NAME} --namespace nightly-submission --role-name nightly-submission-JobExecutionRole
aws emr-containers update-role-trust-policy --cluster-name ${CLUSTER_NAME} --namespace monthly-submission --role-name monthly-submission-JobExecutionRole
aws emr-containers update-role-trust-policy --cluster-name ${CLUSTER_NAME} --namespace adhoc-ml-submission --role-name adhoc-ml-submission-JobExecutionRole

