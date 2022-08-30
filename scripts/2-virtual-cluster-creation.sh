# EKS Namespaces for process isoloation in EKS. 
kubectl create namespace realtime-submission
kubectl create namespace intra-day-submission
kubectl create namespace nightly-submission
kubectl create namespace monthly-submission
kubectl create namespace adhoc-ml-submission


## ServiceName Mapping with RBAC (Role & Rolebinding)
# RBAC permissions and for adding EMR on EKS service-linked role into aws-auth configmap

eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} --namespace realtime-submission --service-name "emr-containers"
eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} --namespace intra-day-submission --service-name "emr-containers"
eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} --namespace nightly-submission --service-name "emr-containers"
eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} --namespace monthly-submission --service-name "emr-containers"
eksctl create iamidentitymapping --cluster ${CLUSTER_NAME} --namespace adhoc-ml-submission --service-name "emr-containers"


#Enable IAM Roles for Service Account (IRSA)
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve

# Register EKS cluster with EMR
# The final step is to register EKS cluster with EMR.

aws emr-containers create-virtual-cluster \
--name realtime-submission-emr-cluster \
--container-provider '{
    "id": "'"${CLUSTER_NAME}"'",
    "type": "EKS",
    "info": {
        "eksInfo": {
            "namespace": "realtime-submission"
        }
    }
}' \
--no-cli-pager

aws emr-containers create-virtual-cluster \
--name intra-day-submission-emr-cluster \
--container-provider '{
    "id": "eks-emr-cluster",
    "type": "EKS",
    "info": {
        "eksInfo": {
            "namespace": "intra-day-submission"
        }
    }
}' \
--no-cli-pager

aws emr-containers create-virtual-cluster \
--name nightly-submission-emr-cluster \
--container-provider '{
    "id": "eks-emr-cluster",
    "type": "EKS",
    "info": {
        "eksInfo": {
            "namespace": "nightly-submission"
        }
    }
}' \
--no-cli-pager

aws emr-containers create-virtual-cluster \
--name monthly-submission-emr-cluster \
--container-provider '{
    "id": "eks-emr-cluster",
    "type": "EKS",
    "info": {
        "eksInfo": {
            "namespace": "monthly-submission"
        }
    }
}' \
--no-cli-pager

aws emr-containers create-virtual-cluster \
--name adhoc-ml-submission-emr-cluster \
--container-provider '{
    "id": "eks-emr-cluster",
    "type": "EKS",
    "info": {
        "eksInfo": {
            "namespace": "adhoc-ml-submission"
        }
    }
}' \
--no-cli-pager