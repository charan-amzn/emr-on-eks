# Sample Job S3 Location
export DEMO_JOBS_PATH=s3://${CLUSTER_NAME}-demojobs-${AWS_ACCOUNT_ID}-${AWS_REGION}
aws s3 mb $DEMO_JOBS_PATH 

# Sample Job
cat << EOF > low-priority-threadsleeper.py
import sys
from time import sleep
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("monthly-submission-low-priority-job").getOrCreate()

def sleep_for_x_seconds(x):sleep(x*20)

sc=spark.sparkContext
sc.parallelize(range(1,6), 5).foreach(sleep_for_x_seconds)

spark.stop()

EOF
aws s3 cp low-priority-threadsleeper.py $DEMO_JOBS_PATH

# Job Submission
export CURRENT_VIRTUAL_CLUSTER=monthly-submission-emr-cluster
export VIRTUAL_CLUSTER_ID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name=='${CURRENT_VIRTUAL_CLUSTER}' && state=='RUNNING' && containerProvider.id=='${CLUSTER_NAME}'].id" --output text)
${EMR_ROLE_ARN}
export POD_TEMPLATE_PATH=s3://${CLUSTER_NAME}-pod-templates-${AWS_ACCOUNT_ID}-${AWS_REGION}

aws emr-containers start-job-run \
--no-cli-pager \
--virtual-cluster-id ${VIRTUAL_CLUSTER_ID} \
--name monthly-submission-low-priority-job \
--execution-role-arn "$(aws iam get-role --role-name monthly-submission-JobExecutionRole --query Role.Arn --output text)" \
--release-label emr-6.4.0-latest \
--job-driver '{
    "sparkSubmitJobDriver": {
        "entryPoint": "'${DEMO_JOBS_PATH}'/low-priority-threadsleeper.py",
        "sparkSubmitParameters": "--conf spark.kubernetes.driver.podTemplateFile=\"'${POD_TEMPLATE_PATH}'/spark_driver_pod_template.yml\" --conf spark.kubernetes.executor.podTemplateFile=\"'${POD_TEMPLATE_PATH}'/lp_spark_executor_pod_template.yml\" --conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=1 --conf spark.driver.cores=1"
        }
}' \
--configuration-overrides='{
    "applicationConfiguration": [
    {
        "classification": "spark-defaults",
        "properties": {
            "spark.dynamicAllocation.enabled":"false",
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
    }],
    "monitoringConfiguration": {
            "persistentAppUI":"ENABLED",
            "cloudWatchMonitoringConfiguration": {
                "logGroupName": "/emr-on-eks/'${CLUSTER_NAME}'/monthly-submission",
                "logStreamNamePrefix": "low-p-"
            }, 
            "s3MonitoringConfiguration": { 
            "logUri": "s3://monthly-submission-logs-'${AWS_ACCOUNT_ID}-${AWS_REGION}'/" 
            }

        }
}'
