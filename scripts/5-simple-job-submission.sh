# Simple Job Submission
export CURRENT_VIRTUAL_CLUSTER=monthly-submission-emr-cluster
export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${CURRENT_VIRTUAL_CLUSTER}' && state=='RUNNING' && containerProvider.id=='${CLUSTER_NAME}'].id" --output text)

cat > emr-request-withlogging.json <<EOF 
{
    "name": "pi-4",
    "virtualClusterId": "${VIRTUAL_CLUSTER_ID}",
    "executionRoleArn": "$(aws iam get-role --role-name monthly-submission-JobExecutionRole --query Role.Arn --output text)",
    "releaseLabel": "emr-6.3.0-latest",
    "jobDriver": {
        "sparkSubmitJobDriver": {
            "entryPoint": "local:///usr/lib/spark/examples/src/main/python/pi.py",
            "sparkSubmitParameters": " --conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=1 --conf spark.driver.cores=1"
        }
    },
    "configurationOverrides": {
        "applicationConfiguration": [
            {
                "classification": "spark-defaults",
                "properties": {
                  "spark.dynamicAllocation.enabled": "false",
                  "spark.kubernetes.executor.deleteOnTermination": "true",
                  "spark.ui.prometheus.enabled":"true",
                  "spark.executor.processTreeMetrics.enabled":"true",
                  "spark.kubernetes.driver.annotation.prometheus.io/scrape":"true",
                  "spark.kubernetes.driver.annotation.prometheus.io/path":"/metrics/executors/prometheus/",
                  "spark.kubernetes.driver.annotation.prometheus.io/port":"4040",
                  "spark.kubernetes.driver.service.annotation.prometheus.io/scrape":"true",
                  "spark.kubernetes.driver.service.annotation.prometheus.io/path":"/metrics/driver/prometheus/",
                  "spark.kubernetes.driver.service.annotation.prometheus.io/port":"4040",
                  "spark.metrics.conf.*.sink.prometheusServlet.class":"org.apache.spark.metrics.sink.PrometheusServlet",
                  "spark.metrics.conf.*.sink.prometheusServlet.path":"/metrics/driver/prometheus/",
                  "spark.metrics.conf.master.sink.prometheusServlet.path":"/metrics/master/prometheus/",
                  "spark.metrics.conf.applications.sink.prometheusServlet.path":"/metrics/applications/prometheus/"
                }
            }
        ],
        "monitoringConfiguration": {
            "persistentAppUI":"ENABLED",
            "cloudWatchMonitoringConfiguration": {
                "logGroupName": "/emr-on-eks/${CLUSTER_NAME}/monthly-submission",
                "logStreamNamePrefix": "pi"
            }, 
            "s3MonitoringConfiguration": { 
            "logUri": "s3://monthly-submission-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}/" 
            }

        }
    }
}
EOF

aws emr-containers start-job-run --cli-input-json file://emr-request-withlogging.json --no-cli-pager
