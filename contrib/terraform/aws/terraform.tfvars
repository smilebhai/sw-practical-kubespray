#Global Vars
aws_cluster_name = "sw-practical-v1"

#VPC Vars
aws_vpc_cidr_block = "10.250.192.0/18"
aws_cidr_subnets_public = ["10.250.224.0/20","10.250.240.0/20"]

#Kubernetes Cluster

aws_kube_master_num = 1
aws_kube_master_size = "t2.small"

aws_etcd_num = 1
aws_etcd_size = "t2.small"

aws_kube_worker_num = 2
aws_kube_worker_size = "t2.small

#Settings AWS ELB

k8s_secure_api_port = 6443
kube_insecure_apiserver_address = "0.0.0.0"

default_tags = {
  Env = "sw-practical"
  Product = "kubespray"
}

inventory_file = "./../../../inventory/hosts"
