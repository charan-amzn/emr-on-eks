# Create CloudWatch logs location
aws logs create-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/realtime-submission
aws logs create-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/intra-day-submission
aws logs create-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/nightly-submission
aws logs create-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/monthly-submission
aws logs create-log-group --log-group-name=/emr-on-eks/${CLUSTER_NAME}/adhoc-ml-submission

# Create S3 bucket for logs (Optinal and for long term retension)

aws s3 mb s3://realtime-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 mb s3://intra-day-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 mb s3://nightly-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 mb s3://monthly-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 mb s3://adhoc-ml-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}

